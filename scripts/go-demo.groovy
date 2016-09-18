node("docker") {

    git "https://github.com/vfarcic/go-demo.git"

    stage("Unit") {

        sh "docker-compose \
      -f docker-compose-test-local.yml \
      run --rm unit"

        sh "docker-compose \
      -f docker-compose-test-local.yml \
      build app"

    }

    stage("Staging") {

        try {

            sh "docker-compose \
        -f docker-compose-test-local.yml \
        up -d staging-dep"

            sh "docker-compose \
        -f docker-compose-test-local.yml \
        run --rm staging"

        } catch(e) {

            error "Staging failed"

        } finally {

            sh "docker-compose \
        -f docker-compose-test-local.yml \
        down"

        }

    }

    stage("Publish") {

        sh "docker tag go-demo \
      localhost:5000/go-demo:2.${env.BUILD_NUMBER}"

        sh "docker push \
      localhost:5000/go-demo:2.${env.BUILD_NUMBER}"

    }

    stage("Prod-like") {

        withEnv([
                "DOCKER_TLS_VERIFY=1",
                "DOCKER_HOST=tcp://${env.PROD_LIKE_IP}:2376",
                "DOCKER_CERT_PATH=/machines/${env.PROD_LIKE_NAME}",
                "HOST_IP=localhost"
        ]) {

            sh "docker service update \
        --image localhost:5000/go-demo:2.${env.BUILD_NUMBER} \
        go-demo"

            sh "docker-compose \
        -f docker-compose-test-local.yml \
        run --rm production"

        }

    }

    stage("Production") {
        withEnv([
                "DOCKER_TLS_VERIFY=1",
                "DOCKER_HOST=tcp://${env.PROD_IP}:2376",
                "DOCKER_CERT_PATH=/machines/${env.PROD_NAME}",
                "HOST_IP=${env.PROD_IP}"
        ]) {

            sh "docker service update \
        --image localhost:5000/go-demo:2.${env.BUILD_NUMBER} \
        go-demo"

            sh "docker-compose \
        -f docker-compose-test-local.yml \
        run --rm production"
        }
    }
}