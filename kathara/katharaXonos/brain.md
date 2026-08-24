# What is this about?

Me and my professor, we are working on some network virtualization functions. Among several things, a recent work has been started on kathara network emulator and ONOS SDN controller. My professor had a conversation with the official team of kathara, and we are trying to put an official contribution. Let me give you the gist of their conversation:

## Alessio (my professor)

```text
Hi Tommaso,

So I'll try to take advantage of your experience with a technical question. I'm not asking you to waste your time, but I'll ask because maybe you have the answer ready and can get back to me in a minute...

For some preliminary testing I'm doing, I tried connecting the Kathara environment to an ONOS instance running in a Docker external to Kathara. To do something clean, I imagine we'd then need to build an ONOS image in the Kathara image repository... right?

Anyway, as a temporary solution, I followed the tutorial with a few modifications:
https://github.com/KatharaFramework/Kathara-Labs/tree/main/tutorials/kathara-external/communicating-with-the-host

Basically, the tutorial asks for external communication. Instead, I want to communicate with a container created with Docker outside Kathara. This is the ONOS container I already have ready and tested a thousand ways.

So:
- I created a docker network br0
- I ran ONOS in a container connected to br0
- I launched a simple Kathara lab with an OVS switch (eth0, 1, and 2 inside OVS; eth3 outside OVS would be the control interface)
- I assigned eth3 a compatible IP address with addressing on br0
- I created a virtual link veth0--veth1 on the host, inserting veth1 into the br0 bridge (as in the tutorial)
- In lab.ext, I connected eth3 of the Kathara switch to veth0

Layer 2 connectivity is present; in fact, ARP and ping work between the ONOS docker and the Kathara docker. However, OpenFlow connectivity doesn't work, and I can't even connect via ssh from the Kathara host to ONOS. I strongly suspect some iptables rule is dropping connections, but I haven't taken any action.

As suggested in the tutorial, I ran it, but nothing changed:
sudo iptables -A FORWARD -i br0 -o br0 -j ACCEPT

Do you have any suggestions? What do I need to publish the ONOS image to the Katharà repository?

Alessio
```

## Tommaso

```text
Ciao Alessio,

Ho appena aggiunto la storia al sito 😄

Per il lab, si assolutamente! I laboratori che abbiamo sono tutti con POX.

Ti dispiace se faccio un post su LinkedIn con la storia?

Grazie mille per il supporto!

A presto,
Tommaso
```

```text
Ciao Alessio,

Ottimo!

Per creare l'immagine ti basta partire dall'immagine di base (kathara/core) e installare ciò che serve per ONOS. Per un esempio puoi guardare l'immagine di pox: https://github.com/KatharaFramework/Docker-Images/blob/main/pox/Dockerfile

Se ti serve una mano per qualsiasi cosa, chiedi senza problemi 🙂

Grazie mille per il supporto!

A presto,
Tommaso
```

## My standings

I am new to kathara but I have good grip on docker and linux. Before I start working I want you to let you know that, I will learn kathara and solve this issue together. So, try to progress this conversation in future in such a way that I can learn and solve issues together. Now, if you have understood well the conversation between my professor and tommaso-I would like to ask you a few qustions.

**What is the core problem?**

The final problem is:

- we have the kathara image: kathara/core:latest

- we have the onos docker image: onosproject/onos:latest

Inside kathara we have several components. The problem is that, my professor is unable to communicate from an OVS inside kathara to the ONOS which is outside kathara env. The problem is not total connectivity error. The issue is, he is able to send arp and icmp packets but openflow and ssh connectivity (tcp) is not working. What my professor suspects is that, it is a `iptables` filtering issue. However, the official team suggests the following solution:

- instead of creating bridge networks and then connect ONOS and kathara, build an image which will contain both images of kathara and ONOS and able to communicate in every possible ways.

And this is the suggested `Dockerfile` from `gemini`:

```dockerfile
FROM kathara/core:latest

# Update repositories and install your exact dependencies
RUN apt-get update && apt-get install -y \
    python2 build-essential perl curl wget zip bzip2 \
    openjdk-11-jdk screen xterm git \
    && rm -rf /var/lib/apt/lists/*

# Download and setup your specific Bazel version
RUN wget https://releases.bazel.build/6.0.0/rolling/6.0.0-pre.20220421.3/bazel-6.0.0-pre.20220421.3-linux-x86_64 -O /usr/bin/bazel \
    && chmod +x /usr/bin/bazel

# Set the environment variable equivalent to your .bashrc
ENV ONOS_ROOT=/root/onos-b5g-open

# Clone your specific 'dev' branch
RUN git clone -b dev https://github.com/bhuiyan-chafi/onos-b5g-open.git $ONOS_ROOT

# Set the working directory to the ONOS root
WORKDIR $ONOS_ROOT

# Compile the code so it is ready to go when the container boots
RUN bazel build onos

# When Kathará starts this node, source the profile and fire up ONOS
CMD ["/bin/bash", "-c", "source $ONOS_ROOT/tools/dev/bash_profile && ok clean"]
```
