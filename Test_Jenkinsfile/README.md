# Test Jenkins Through Docker Agent

Testing Jenkins using a Docker agent allows for a flexible and isolated environment to run your CI/CD pipelines. Below is a brief description of how to set up and utilize a Docker agent for testing Jenkins.

## Overview

- **Docker Agent**: A Docker agent in Jenkins runs jobs inside Docker containers, providing a clean environment for each build.
- **Benefits**: This approach ensures consistency, reduces dependency conflicts, and simplifies the setup process.

## Setup Steps

1. **Install Docker**: Ensure Docker is installed on the Jenkins server or the host machine.
2. **Configure Jenkins**: 
   - Install the Docker Pipeline and Docker plugins in Jenkins.
   - Configure Docker in Jenkins under Manage Jenkins.
3. **Create a Jenkinsfile**: Define your pipeline in a Jenkinsfile.

## Execution

When the pipeline is triggered, Jenkins will pull the specified Docker image, create a container, and execute the defined steps within that container. This ensures that the testing environment is consistent and isolated from other builds.

## Conclusion

Using a Docker agent for testing in Jenkins enhances the reliability and maintainability of your CI/CD processes by leveraging containerization. This method allows for easy scaling and management of dependencies across different projects.

## Additional Resources

For detailed instructions on configuring Jenkins to use a Docker agent, along with a history of all the commands used, check out my blog: [Harnessing Docker Agents](https://jasaiblogs.hashnode.dev/harnessing-docker-agents-enhancing-your-cicd-pipeline-efficiency#heading-using-a-docker-agent-in-jenkins-for-testing-environment-setup).

## Command History

1. `sudo yum install -y openjdk-17-jre`
2. `wget https://download.oracle.com/java/17/archive/jdk-17.0.11_linux-x64_bin.rpm`
3. `sudo yum install -y jdk-17.0.11_linux-x64_bin.rpm`
4. `uname -m`
5. `sudo yum install -y docker`
6. `docker ps`
7. `sudo service docker start`
8. `sudo usermod -a -G docker ec2-user`
9. `docker ps`
10. `java -version`
11. `docker run -d -p 8080:8080 -p 50000:50000 --restart=on-failure -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts-jdk17`
12. `docker ps`
13. `cat /var/jenkins_home/secrets/initialAdminPassword`
14. `docker exec nifty_vaughan cat /var/jenkins_home/secrets/initialAdminPassword`
15. `docker stop 188ebafd79d0`
16. `docker run -d -p 8080:8080 -p 50000:50000 --restart=on-failure -v jenkins_home:/var/jenkins_home jenkins jenkins/jenkins:lts-jdk17`
17. `docker run -d -p 8080:8080 -p 50000:50000 --restart=on-failure --name jenkins -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts-jdk17`
18. `docker ps`
19. `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
20. `docker ps`
21. `docker stop 16152a181014`
22. `docker ps -a`
23. `docker ps -a`
24. `docker start 16152a181014`
25. `docker ps -a`
26. `docker stop 16152a181014`
27. `docker run -d --name jenkins -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts`
28. `docker run -d --name jenkins2 -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts`
29. `docker ps`
30. `docker exec -it jenkins2 /bin/bash`
31. `docker ps -a`
32. `docker run -d --name jenkins3 -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts`
33. `docker ps -a`
34. `docker logs 3e575a24b4f8`
35. `sudo chown -R 1000:1000 /var/jenkins_home`
36. `ls -ld /var/jenkins_home`
37. `docker ps -a`
38. `docker rm 3e575a24b4f8`
39. `docker rm e80b348dd847`
40. `docker ps -a`
41. `docker run -d --name jenkins3 -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts`
42. `docker ps -a`
43. `docker exec -it jenkins3 /bin/bash`
44. `docker stop jenkins3`
45. `docker rm jenkins3`
46. `docker ps -a`
47. `docker start jenkins3`
48. `docker start jenkins`
49. `curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null`
50. `echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null`
51. `sudo apt-get update`
52. `sudo apt-get install jenkins`
53. `curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null`
54. `sudo yum install jenkins`
55. `docker --version`
56. `docker --version`
57. `sudo usermod -aG docker jenkins`
58. `sudo systemctl restart docker`
59. `sudo systemctl restart jenkins`
60. `docker --version`
61. `docker ps`
62. `docker exec -it jenkins /bin/bash`
63. `whoami`
64. `docker exec -it jenkins /bin/bash`
65. `docker exec -u root -it jenkins /bin/bash`
66. `docker ps`
67. `docker stop jenkins`
68. `docker rm jenkins`
69. `docker run -d --name jenkins -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts`
70. `docker exec -it jenkins /bin/bash`
71. `docker exec -it --user root jenkins /bin/bash`
72. `docker restart jenkins`
73. `docker ps`
74. `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
75. `sudo chmod 666 /var/run/docker.sock`
76. `node --version`
77. `docker exec -it jenkins /bin/bash`
78. `node --version`
79. `docker ps`
80. `history`
