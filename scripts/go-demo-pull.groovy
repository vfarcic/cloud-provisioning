node("docker") {

  stage("Pull") {
    git "https://github.com/vfarcic/go-demo.git"
  }

  stage("Unit") {
  }

  stage("Staging") {
  }

  stage("Publish") {
  }

  stage("Prod-like") {
  }

  stage("Production") {
  }

}
