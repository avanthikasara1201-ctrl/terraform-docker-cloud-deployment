module "vpc" {
  source = "./module-terraform/vpc"

  vpc_cidr = "10.0.0.0/16"
}
module "ec2" {
  source = "./module-terraform/ec2"

  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_id
}

module "ecr" {
  source = "./module-terraform/ecr"
}
