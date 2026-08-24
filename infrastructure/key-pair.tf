resource "aws_key_pair" "medicore" {
  key_name = "${var.project_name}-ssh-key"

  public_key = file(
    pathexpand(var.ssh_public_key_path)
  )

  tags = {
    Name    = "${var.project_name}-ssh-key"
    Purpose = "SSH access to MediCore Linux infrastructure"
  }
}