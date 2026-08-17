# Networking (VPC) Terraform template
#
# Multi-cloud starting point for a VPC/VNet with public + private subnets,
# internet egress for both tiers, and baseline security groups. This is what
# the autoscaling and rds templates' subnet_ids / security_group_ids inputs
# are meant to be filled in from — put load-balanced/public compute in the
# public subnets and the ASG/RDS instances in the private ones.
#
# Only ONE provider block should be active at a time — AWS is active by
# default. To target a different cloud: comment out the active provider +
# its resources, uncomment the one you want, and set cloud_provider in
# terraform.tfvars accordingly.

locals {
  name = "${var.project_name}-${var.environment}"

  # var.aws_availability_zones is optional — fall back to auto-selected AZs
  # when left empty, sized to cover whichever subnet list is longer.
  aws_subnet_count = max(length(var.aws_public_subnet_cidrs), length(var.aws_private_subnet_cidrs))
  aws_azs = length(var.aws_availability_zones) > 0 ? var.aws_availability_zones : slice(
    data.aws_availability_zones.available[0].names,
    0,
    min(local.aws_subnet_count, length(data.aws_availability_zones.available[0].names))
  )
  aws_nat_gateway_count = var.aws_single_nat_gateway ? 1 : length(var.aws_public_subnet_cidrs)
}

# --- AWS (active) ---

provider "aws" {
  region = var.aws_region
}

# Only queried when aws_availability_zones is left empty — an explicit list
# skips this entirely, including the ec2:DescribeAvailabilityZones
# permission it would otherwise require.
data "aws_availability_zones" "available" {
  count = length(var.aws_availability_zones) > 0 ? 0 : 1

  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = var.aws_enable_dns_hostnames
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = local.name
  })
}

resource "aws_subnet" "public" {
  count = length(var.aws_public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.aws_public_subnet_cidrs[count.index]
  availability_zone       = element(local.aws_azs, count.index % length(local.aws_azs))
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${local.name}-public-${count.index}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.aws_private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.aws_private_subnet_cidrs[count.index]
  availability_zone = element(local.aws_azs, count.index % length(local.aws_azs))

  tags = merge(var.tags, {
    Name = "${local.name}-private-${count.index}"
    Tier = "private"
  })
}

# One EIP + NAT gateway per local.aws_nat_gateway_count (1 if
# aws_single_nat_gateway, else one per public subnet/AZ).
resource "aws_eip" "nat" {
  count  = local.aws_nat_gateway_count
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${local.name}-nat-${count.index}"
  })
}

resource "aws_nat_gateway" "this" {
  count = local.aws_nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${local.name}-nat-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name}-public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# One private route table per private subnet, each pointing at either the
# single shared NAT gateway or its own AZ-local one.
resource "aws_route_table" "private" {
  count = length(var.aws_private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name}-private-${count.index}"
  })
}

resource "aws_route" "private_nat" {
  count = length(aws_route_table.private)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  # Modulo guards against private_subnet_cidrs outnumbering
  # public_subnet_cidrs when aws_single_nat_gateway = false (one NAT per
  # public subnet/AZ) — without it, a longer private list would index past
  # the end of aws_nat_gateway.this.
  nat_gateway_id = aws_nat_gateway.this[count.index % local.aws_nat_gateway_count].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Baseline security groups — narrow these further per app rather than
# reusing "web" for anything beyond an internet-facing HTTP(S) tier.
resource "aws_security_group" "web" {
  name_prefix = "${local.name}-web-"
  description = "Inbound HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name}-web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "internal" {
  name_prefix = "${local.name}-internal-"
  description = "All traffic between resources inside the VPC (app <-> DB tier)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Intra-VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name}-internal"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# --- GCP (inactive — uncomment to use) ---
#
# GCP subnets aren't inherently public/private the way AWS ones are —
# reachability depends on whether an instance gets an external IP, not the
# subnet config. Private egress still needs Cloud Router + Cloud NAT.

# provider "google" {
#   project = var.gcp_project_id
#   region  = var.gcp_region
# }
#
# resource "google_compute_network" "this" {
#   name                    = local.name
#   auto_create_subnetworks = false
# }
#
# resource "google_compute_subnetwork" "public" {
#   name          = "${local.name}-public"
#   ip_cidr_range = var.gcp_public_subnet_cidr
#   region        = var.gcp_region
#   network       = google_compute_network.this.id
# }
#
# resource "google_compute_subnetwork" "private" {
#   name                     = "${local.name}-private"
#   ip_cidr_range            = var.gcp_private_subnet_cidr
#   region                   = var.gcp_region
#   network                  = google_compute_network.this.id
#   private_ip_google_access = true
# }
#
# resource "google_compute_router" "this" {
#   name    = "${local.name}-router"
#   region  = var.gcp_region
#   network = google_compute_network.this.id
# }
#
# resource "google_compute_router_nat" "this" {
#   name                               = "${local.name}-nat"
#   router                             = google_compute_router.this.name
#   region                             = var.gcp_region
#   nat_ip_allocate_option             = "AUTO_ONLY"
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
# }
#
# resource "google_compute_firewall" "web" {
#   name    = "${local.name}-web"
#   network = google_compute_network.this.id
#
#   allow {
#     protocol = "tcp"
#     ports    = ["80", "443"]
#   }
#
#   source_ranges = ["0.0.0.0/0"]
# }
#
# resource "google_compute_firewall" "internal" {
#   name    = "${local.name}-internal"
#   network = google_compute_network.this.id
#
#   allow {
#     protocol = "all"
#   }
#
#   source_ranges = [var.gcp_public_subnet_cidr, var.gcp_private_subnet_cidr]
# }

# --- Azure (inactive — uncomment to use) ---

# provider "azurerm" {
#   features {}
# }
#
# resource "azurerm_resource_group" "this" {
#   name     = "${local.name}-rg"
#   location = var.azure_location
#   tags     = var.tags
# }
#
# resource "azurerm_virtual_network" "this" {
#   name                = local.name
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   address_space       = [var.azure_vnet_cidr]
#   tags                = var.tags
# }
#
# resource "azurerm_subnet" "public" {
#   name                 = "${local.name}-public"
#   resource_group_name = azurerm_resource_group.this.name
#   virtual_network_name = azurerm_virtual_network.this.name
#   address_prefixes     = [var.azure_public_subnet_cidr]
# }
#
# resource "azurerm_subnet" "private" {
#   name                 = "${local.name}-private"
#   resource_group_name = azurerm_resource_group.this.name
#   virtual_network_name = azurerm_virtual_network.this.name
#   address_prefixes     = [var.azure_private_subnet_cidr]
# }
#
# resource "azurerm_network_security_group" "web" {
#   name                = "${local.name}-web-nsg"
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#
#   security_rule {
#     name                       = "allow-http-https"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_ranges    = ["80", "443"]
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#
#   tags = var.tags
# }
#
# resource "azurerm_public_ip" "nat" {
#   name                = "${local.name}-nat-ip"
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   allocation_method   = "Static"
#   sku                  = "Standard"
# }
#
# resource "azurerm_nat_gateway" "this" {
#   name                = "${local.name}-nat"
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   sku_name             = "Standard"
# }
#
# resource "azurerm_nat_gateway_public_ip_association" "this" {
#   nat_gateway_id       = azurerm_nat_gateway.this.id
#   public_ip_address_id = azurerm_public_ip.nat.id
# }
#
# resource "azurerm_subnet_nat_gateway_association" "private" {
#   subnet_id      = azurerm_subnet.private.id
#   nat_gateway_id = azurerm_nat_gateway.this.id
# }
