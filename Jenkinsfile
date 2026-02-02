pipeline {
  agent any

  environment {
    AWS_REGION = "us-east-1"

    // Jenkins Credentials IDs (you create these in Jenkins)
    // 1) "aws-access-key-id" (secret text) OR use one "aws-creds" as username/password
    // 2) "aws-secret-access-key" (secret text)
    // 3) "ec2-ssh-key" (SSH Username with private key) OR secret file
    SSH_KEY_CRED_ID = "ec2-user"
  }

  stages {
    stage("Checkout") {
      steps {
        checkout scm
      }
    }

    stage("Terraform Init") {
      steps {
        dir("terraform") {
          sh "terraform --version"
          sh "terraform init"
        }
      }
    }

    stage("Terraform Plan") {
      steps {
        dir("terraform") {
          withCredentials([
            string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
            string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
          ]) {
            sh """
              export AWS_DEFAULT_REGION=${AWS_REGION}
              terraform plan \
                -var region=${AWS_REGION} \
                -var ssh_key_name=devops-terraform \
                -out=tfplan
            """
          }
        }
      }
    }

    stage("Terraform Apply") {
      steps {
        dir("terraform") {
          withCredentials([
            string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
            string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
          ]) {
            sh """
              export AWS_DEFAULT_REGION=${AWS_REGION}
              terraform apply -auto-approve tfplan
            """
          }
        }
      }
    }

    stage("Generate Ansible Inventory") {
      steps {
        dir("terraform") {
          script {
            def ip = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
            writeFile file: "../ansible/inventory.aws_ec2.yml", text: """\
all:
  hosts:
    web1:
      ansible_host: ${ip}
      ansible_user: ec2-user
      ansible_ssh_private_key_file: ${WORKSPACE}/ec2_key.pem
"""
          }
        }
      }
    }

    stage("Run Ansible") {
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: "${SSH_KEY_CRED_ID}", keyFileVariable: 'KEYFILE')
        ]) {
          sh """
            cp "$KEYFILE" ec2_key.pem
            chmod 600 ec2_key.pem
            cd ansible
            ansible --version
            ansible-playbook site.yml
          """
        }
      }
    }

    stage("Smoke Test") {
      steps {
        dir("terraform") {
          script {
            def ip = sh(script: "terraform output -raw public_ip", returnStdout: true).trim()
            sh "curl -sSf http://${ip} | head"
          }
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline finished."
    }

    // Optional: auto destroy so you don’t pay $$$
    // Uncomment if you want every run to clean up
    /*
    cleanup {
      dir("terraform") {
        withCredentials([
          string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
          string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh """
            export AWS_DEFAULT_REGION=${AWS_REGION}
            terraform destroy -auto-approve \
              -var region=${AWS_REGION} \
              -var ssh_key_name=YOUR_KEYPAIR_NAME
          """
        }
      }
    }
    */
  }
}

