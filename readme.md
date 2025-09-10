# Emulating SDN - ONOS, Mininet, Building Application on ONOS

This repo is inspired from the SDN part of our Teletraffic and Wireless Communication course taken by Professor Alessio Giorgetti. The overall repo is forked from two other repos:

- [NETM-Scripts - By Prof. Alessio Giorgetti](https://github.com/alessiocnit/NETM-scripts-git)
- [Mininet Docker for Apple Silicon - Amir Reza](https://github.com/amirreza225/MinininetDocker-AppleSiliconCompatible)

Both of them did an excellent job to emulate a virtual network on linux(ubuntu). In this repo I have added a bridge to make a communication path within these repos. So, let's start.

`I would request you to read the related comments before executing a command`.

## Author

- ASM CHAFIULLAH
- Master's Student of Computer Science and Networking
- University of Pisa, Italy
- a.bhuiyan@studenti.unipi.it or
- chafiullah@outlook.com

## Initial Challenge

We studied [ONOS](https://opennetworking.org/onos/) SDN controller during our course. The controller was excellent but for some reason it has been dropped and no longer having supports from the community. There are emerging technologies, but still ONOS gives a very in-depth knowledge about flow-rules, packet-forwarding, QoS, etc. And for students it is the best. But installing ONOS in different machines(having different CPU architecture) was and still is challenging.

So, we are trying to dockerize the whole process so that we can: run linux virtual network topologies, with mininet, using ONOS controller and building ONOS application using Bazel and Maven using docker. And the whole process becomes platform independent.

## If you have a MAC

Yes, the main target was the students with MAC machines. Even this repo was built and tested in a MAC Air M2, 8GB, Sequoia 15.6.1.

## Starting the Process

First you have to clone this repo.

```bash
git clone https://github.com/bhuiyan-chafi/sdn-docker.git
```

After that you have to download two additional files which are stored in my `OneDrive`. Why? Because the images are pretty big to be dumped in github, github is free but doesn't mean we can put files of MBs, haha! So here are the files(if you face any error, you can send me an email):

- [mininet-image](https://unipiit-my.sharepoint.com/:u:/g/personal/a_bhuiyan_studenti_unipi_it/EUGaBEfN8WdOueH1SmF8SQYB3Bl_VgczgLRvH0inDB1PuA?e=PhVdLb)
- [onos-image](https://unipiit-my.sharepoint.com/:u:/g/personal/a_bhuiyan_studenti_unipi_it/EY0jTZw2hPxCkO3q1cUSK60B1EoGKRtX_OQ9d2BQm3j3QA?e=XBtHVP)

So, I guess now you have the images in the same folder of this `github repository`. **Make sure of this, otherwise you will face issues while executing the script**. Your current directory must look like this:

![directory-image](/images/directory.png)

which means you have all the files and ready to go.

## Start with the scripts

After cloning `scripts(.sh)` files should remain `executable`. But to be sure, you can repeat the process again:

```bash
cd 'the git repo directory'
chmod +x docker-run.sh
chmod +x configure-onos.sh
```

### Available commands

```bash
./docker-run.sh help
```

![options](/images/options.png)

## Build the images

```bash
./docker-run.sh build
```

This command will build a new network bridge within docker to connect your containers together. Now, here I want to explain a few things. Intentionally, the network subnet has been separated from our course. For that you have to do a few things differently but trust me it's too simple. I didn't keep the same subnet like our course because in our course we are using a linux `VM` provided by our professor. Even your colleagues are using that `VM` but you are emulating the whole process in your physical machine and there are chances that you might have used the `IPs` of docker `172.17.0.0/16` subnet for other applications. So a new network bridge `172.28.0.0/16` has been created for this operation and ONOS has been instructed to occupy one IP from there as a host.

If your build is successful you must see something like this:

![docker-build](/images/docker-build.png)

![docker-build](/images/docker-build-gui.png)

## Next step is to create the Mininet Container

For ONOS you just have to start the container because it doesn't come with an iterative shell or bash. The whole image is wrapped with necessary files required to run the engine. For bazel and maven built, we have a different pipeline(upcoming).

```bash
./docker-run.sh run_mininet
```

![docker-build](/images/mininet-container.png)

Make sure you see the same messages regarding `OpenVSwitch` otherwise you can't proceed further. If everything is fine you can test it with a simple `python` script that creates a simple topology without any SDN controller.

```bash
# in your mininet-dev container
# root@582d7524b0c9:/app#
cd projects/
ls
python3 test_standalone.py
# which starts a mininet topology for you
# from the mininet shell
mininet> pingall
```

which outputs a topology like this:

![docker-build](/images/mininet-standalone.png)

So, we are 100% sure that `mininet` is able to emulate our virtual network. Now exit from `mininet` and clear the topology.

```bash
# from the mininet shell
mininet> exit
# from the container shell
sudo mn -c
```

![docker-build](/images/mininet-clean.png)

## Starting the ONOS container

```bash
# Open a new terminal in the same directory (git-repo)
./docker-run.sh run_onos
```

Will create an `ONOS` container and onos inside it. I didn't run the container in detached(-d) mode, so that you can see the server log. Sometimes, it helps seeing the logs if you run into an error. Finally you will see something at the beginning and at the end:

![docker-build](/images/onos-starting.png)

![docker-build](/images/onos-started.png)

`ONOS GUI is running inside docker: 172.28.0.11:8181` and `OpenFlow is running on port 6653` and `ONOS CLI on 8101`. Both of the ports are bound to your physical machine's port: 8181, 6653, 8101. The container run may fail if any of these ports are occupied by some other applications in your machine. So, do your thing and check if the ports are free in your machine and then try again(if you ran into any error).

`You must never do anything else in terminal except checking the logs(if required)`. This one will keep running the server.

The next step is to `activate` the `ONOS Applications` for `openFlow`, `arp` and `forwarding`. For that you already have a `script` inside the directory. So, open a new terminal and execute the script:

```bash
# from the git-repo directory
./configure-onos.sh
```

Since we have bound `ONOS` with our local machine this `API` calls are slightly different than the ones' our professor might be executing. But it's obvious. If your API call is successful:

![docker-build](/images/onos-api-calls.png)

It's time to go the `ONOS GUI` and check if everything is fine. For that, go to your browser and paste this [login-page-link](http://localhost:8181/onos/ui/login.html).

`Credentials to login:`

- username: karaf
- password: karaf

`In case you are looking for the API docs:` go to this [api-docs-page](http://localhost:8181/onos/v1/docs/).

This will be your dashboard explaining the existing topologies(currently it should be empty):

![docker-build](/images/onos-gui.png)

Check the applications, if they are activated(very important):

![docker-build](/images/onos-apps-active.png)

## Let's check mininet and onos together

Come back to the mininet shell and executing the controlled topology:

```bash
# from mininet bash
# root@582d7524b0c9:/app/projects#
python3 test.py
```

Must give you a topology like this:

![docker-build](/images/mininet-controlled-1.png)

Now! Don't get frightened by seeing the controller cannot be contacted. It happens because onos is running in another container on top of your own operating system. Since there is no dedicated kernel inside the docker container, mininet(which is using an ubuntu kernel) cannot communicate directly with onos at OS level. But we have specified the controller's IP and port, thus the topology will for sure communicate with the controller if everything is fine. To be sure let's execute this command from the `mininet shell`:

```bash
mininet>sh ovs-vsctl show | grep -A2 Controller
```

and you must see an output like this:

![docker-build](/images/mininet-controlled-confirm.png)

Come on! Let's ping the hosts and see the topology on ONOS(can't wait!):

```bash
mininet> pingall
```

![docker-build](/images/mininet-controlled-pinged.png)

In ONOS controller > Topology page > press control+h(for mac), ctrl+h(windows/linux) and this should be visible:

![docker-build](/images/onos-topo-controlled.png)

## If you want to connect to ONOS CLI

Open a new terminal and execute this command:

```bash
# from anywhere in the terminal
ssh -p 8101 karaf@localhost
# password is: karaf
```

This will take you to the `ONOS-CLI` because we have bound the port `8101` with our local machine. Here is the example:

![docker-build](/images/onos-cli.png)

## Operations related to the course

There are some operations that you have to perform which is going to be different from what you see in the class or in the slides. But it's not completely different, just some additional steps since everything is not in one place.

### How to get inside of a namespace(h1,h2...hx)

Since we don't have or you can say can't have(you can read in google what are the reasons) xterm, we have to use the same shell for executing commands inside a namespace. To do that:

```bash
mininet> h1 bash
# you are transferred to h1 domain now
# root@582d7524b0c9:/app/projects# but it's inside h1 so, don't get confused
ifconfig
```

![docker-build](/images/namespace-shell.png)

Then execute this to return back:

```bash
# root@582d7524b0c9:/app/projects# but it's inside h1 so, don't get confused
exit
# and you are back to mininet shell again
mininet>
```

So, execute whatever command(route, arp, traceroute, infconfig, etc.) you need inside the namespace like this.

## But how can I run two shell to test the iperf?

Yes, that's the tricky part but don't worry we have that covered as well. Here are the steps:

- make sure one shell is running with mininet
- open another shell

```bash
docker exec -it mininet-dev bash
# takes you inside the container
# find out what is the PID(process identifier)
# root@582d7524b0c9:/app#
pgrep -f 'mininet:h2'
# must show a number(ex: 821)
mnexec -a 821 bash
# root@582d7524b0c9:/app#
# but you are inside the namespace
# for proof
ifconfig
```

![docker-build](/images/namespace-second-shell.png)

- from the first mininet terminal go to any namespace just like before

```bash
h1 bash
```

Now run `iperf` from the namespaces:

![docker-build](/images/iperf-server.png)

![docker-build](/images/iperf-client.png)

It also works with limited bandwidth, give it a try!

That's all from me, :) I hope this repo helps. The next step is to build another container for bazel and maven which I still don't I would be able to accomplish or no! But, I am very hopeful. Happy Networking!
