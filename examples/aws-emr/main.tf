provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "emr_subnet" {
  vpc_id = "${aws_vpc.main_vpc.id}"
  cidr_block = "10.0.0.0/24"
}

resource "aws_iam_instance_profile" "emr_profile" {
  name = "sample_emr_profile"
}

resource "aws_iam_role" "sample" {
  name = "a_sample_role_name"
  assume_role_policy = <<EOF
    {
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
EOF
}

resource "aws_emr_cluster" "sample_cluster" {

  ###
  # Step 1: Software and Steps
  release_label = "emr-5.4.0"

  # Flink, Hadoop, Hive, Mahout, Pig, and Spark
  applications = ["Spark"]

  configurations = "./configurations.json"

  # Add steps: A step is a unit of work you submit to the cluster.
  # For instance, a step might contain one or more Hadoop or Spark jobs.
  # You can also submit additional steps to a cluster after is running

  ###
  # Step 2: Hardware
  ec2_attributes {
    subnet_id = "${aws_subnet.emr_subnet.id}"
    instance_profile = "${aws_iam_instance_profile.emr_profile.id}"
  }
  master_instance_type = "m3.xlarge"
  core_instance_type = "m3.xlarge"
  core_instance_count = 1

  ###
  # Step 3: General Cluster Settings
  name = "emr-sample-cluster"
  log_uri = "s3://foo/emr_cluster/logs"
  tags {
    foo = "bar"
  }

  bootstrap_action {
    path = "s3://elasticmapreduce/boostrap-actions/run-if"
    name = "runif"
    args = ["instance.isMaster=true", "echo Running on master node"]
  }

  termination_protection = false
  keep_job_flow_alive_when_no_steps = true

  ###
  # Step 4: Security
  service_role = "${aws_iam_role.sample.arn}"
}
