# arkcase-kubernetes-cross-platform
ArkCase setup Kubernetes development environment cross platform

## Windows:
The following steps should be performed on Windows installation only once, only the first time when you set up ArkCase

### Paths
Paths used OOTB. If you want to use different paths, go in the scripts and change accordingly:
- <code>C:/work</code> - All work by the scripts are going to be done here
- <code>C:/work/arkcase</code> - Here should be ArkCase source code
- <code>C:/work/acm-config</code> - Here should be the Configuration source code
- <code>C:/work/minikube</code> - Here will be downloaded Minikube EXE file
- <code>C:/work/arkcase/acm-standard-applications/war/arkcase/target/*.war</code> - Location of the ArkCase WAR file. Change it in <code>deploy-arkcase.sh</code>
- <code>C:/work/acm-config/target/*.zip</code> - Location of the Configuration (.arkcase) ZIP file. Change it in <code>deploy-arkcase.sh</code>
- <code>C:/work/apache-tomcat-9.0.93</code> - Here will be downloaded Tomcat if you decide to run ArkCase locally, not in the cluster. Don't need to use this one, you can use other if you have already installed Tomcat on the machine

### Run
1. Open GitBash session with admin privileges
2. Navigate to "arkcase-kubernetes-cross-platform" folder previously taken from this repository
3. Start the script: <code>./start.sh</code> 
4. The following menu will be shown:<br><br>
<code>
   ********* Prepare Development Environment ********* :<br>
   1\. Install Development Tools (Java, Maven, NodeJS, Yarn, etc.)<br><br>
   ********* Running ArkCase in cluster - Remote Debug (OOTB) ********* :<br>
   2\. Install Environment (Minikube, kubectl, Helm, hyperV)<br>
   3\. Install ArkCase (Start Minikube, install ArkCase using Helm, add host names in \"host\" file)<br>
   4\. Deploy ArkCase (Deploy ArkCase and Config server to Minikube. ArkCase/Config path should be updated in the script)<br><br>
   ********* Running ArkCase and Config outside the cluster - Local Debug ********* :<br>
   NOTE: ALL PREVIOUS COMMANDS FROM 1-4 MUST BE FINISHED SUCCESSFULLY FIRST TO BE ABLE TO RUN ANY COMMAND BELOW<br>
   5\. Prepare Local Environment (pull arkcase configuration from cluster, get and install necessary certificates on Windows, etc.)<br>
   6\. Start port forwarding for configured services (services can be found in the script)<br>
   7\. Stop port forwarding for configured services (services can be found in the script)<br><br>
   ********* Helpers ********* :<br>
   8\. Import certificates<br>
   9\. Delete port forwarding lock file<br>
   10\. Restart Environment (delete Minikube and start again)<br>
   11\. Print IntelliJ Run Configuration Example<br>
   12\. Print hosts in \"host\" file configured on the 127.0.0.1<br>
   e. Exit<br>
</code>
<br>
5. If you are setting the development environment for the first time (you don't have Java, Maven, NodeJS, Yarn, etc), execute the command: <code>1</code>
6. If you are setting the Minikube environment for the first time, execute the command: <code>2</code>
7. If you are setting the Minikube and ArkCase (helm install) for the first time, execute the command: <code>3</code>.
    - NOTE: This is the start command located in the <code>install-arkcase.sh</code>
      - <code>minikube start --vm=true --driver=$driver --cpus=6 --memory=16000m;</code>
      - That means 6 CPU and 16GB RAM memory will be dedicated to the minikube. Change this per your needs. Also, we are using default disk space, which is 20GB. You can change it with adding the parameter in the start command. Visit the official site for more information: <url>https://minikube.sigs.k8s.io/docs/</url>
8. If you want to deploy arkcase.war and config.zip archives in Kubernetes after successful build on Windows, execute the command: <code>4</code>
   - Open "arkcase-kubernetes-cross-platform/scripts/deploy-arkcase.sh" and change the paths to arkcase.war and config.zip if you are not using our OOTB paths
9. If you want to run ArkCase and Config Server on Windows, and all other services to stay in the Kubernetes cluster, execute the command: <code>5</code><br>
   - It will take the configuration from the Kubernetes cluster, and will add to "$HOME/.arkcase".
   - It will take all necessary certificates from the cluster, and will import in "$HOME/.arkcase/acm/private" keystore/truststore
   - Start the Config Server on Windows
   - Start ArkCase from your IDE from Windows
10. After successful start Kubernetes cluster, port forwarding should be executed to be able to access services from Windows to Kubernetes cluster:
    - Execute the command: <code>6</code>
11. If you want to stop port forwarding, execute the command: <code>7</code>
12. For helping and troubleshooting with some issues, run the following commands:
    - When certificates are outdated, execute the command: <code>8</code>
    - When port forwarding have issues (always is saying that they are already running, but still you cannot access the service), execute the command: <code>9</code>
    - When you need to restart the whole Kubernetes cluster (delete it and create again), execute the command: <code>10</code>
    - If you want to see what VM options you need to configure when you want to use Intellij IDEA, execute the command: <code>11</code>
    - If you want to see what hosts are configured in host file while the command \"3. Install ArkCase\", execute the command: <code>12</code>
13. For exit, execute the command: <code>e</code>

### Helpful tips and commands
1. You can use "kubectl" and "helm" commands on Windows, and automatically they will be executed in Minikube
2. <code>minikube dashboard</code> - will start Kubernetes UI on the browser
3. Equivalent command like "watch" on Linux, here on Windows is:
   - Go to the folder "arkcase-kubernetes-cross-platform"
   - Execute the command, for example: <code>./watch.sh kubectl get pods</code>
4. Ensure that you will do <code>minikube stop</code> before shutting down your computer. The best way to avoid potential problems
5. After the first setup, to start the minikube you need just to execute <code>minikube start</code> since all other configuration will be remembered
