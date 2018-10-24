# ---------------------------------------------------------------------------------------------------------------------
# TO RUN A SINGLE ECS TASK
# We also associate the ECS Service with an ELB, which can distribute traffic across the ECS Tasks.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_service" "service" {
  name = "${var.name}"
  cluster = "${var.ecs_cluster_id}"
  task_definition = "${aws_ecs_task_definition.task.arn}"
  desired_count = "${var.desired_count}"

  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent = "${var.deployment_maximum_percent}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ECS TASK TO RUN A DOCKER CONTAINER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "task" {
  family = "${var.name}"
  container_definitions = <<EOF
[
  {
    "name": "${var.name}",
    "image": "${var.image}:${var.image_version}",
    "cpu": ${var.cpu},
    "memory": ${var.memory},
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.container_port},
        "hostPort": ${var.host_port},
        "protocol": "tcp"
      }
    ],
    "environment": [${join(",", data.template_file.env_vars.*.rendered)}]
  }
]
EOF
}

# Convert the environment variables the user passed-in into the format expected for for an ECS Task:
#
# "environment": [
#    {"name": "NAME", "value": "VALUE"},
#    {"name": "NAME", "value": "VALUE"},
#    ...
# ]
#
data "template_file" "env_vars" {
  count = "${var.num_env_vars}"
  template = <<EOF
{"name": "${element(keys(var.env_vars), count.index)}", "value": "${lookup(var.env_vars, element(keys(var.env_vars), count.index))}"}
EOF
}