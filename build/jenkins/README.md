```bash
docker build -t vfarcic/jenkins-devops .

docker run -d --name jenkins \
    -p 8080:8080 \
    -p 50000:50000 \
    vfarcic/jenkins-devops

open http://localhost:8080/jenkins
```