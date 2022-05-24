#!/bin/bash
virsh start $2 &>/dev/null
case "$1" in
disk)
	if [ "$3" == "-a" ];then
		qemu-img create -f qcow2 /var/lib/libvirt/images/$4.qcow2 $5 &>/dev/null
		echo "<disk type='file' device='disk'>
			<driver name='qemu' type='qcow2'/> 
			<source file='/var/lib/libvirt/images/$4.qcow2'/> 
			<target dev='vdb' bus='virtio'/>
		</disk>" > /root/$4.xml
		virsh attach-device $2 /root/$4.xml --persistent
	elif [ "$3" == "-d" ];then
		virsh detach-disk $2 /var/lib/libvirt/images/$4.qcow2 --persistent
		rm -rf /root/$4.xml
	else
		echo -e "\033[31m 输入有误，可执行 --help 查看帮助信息\033[0m"
	fi
	;;
net)
	if [ "$3" == "-a" ];then
		virsh attach-interface $2 --type bridge --source br0
	elif [ "$3" == "-d" ];then
		mac=`virsh domiflist $2|grep br0|awk '{print $5}'`
		virsh detach-interface $2 --type bridge --mac $mac
	elif [ "$3" == "-c" ];then
		virsh attach-interface $2 --type bridge --source br0
		virsh attach-interface $2 --type bridge --source br0 --config
	else
		echo -e "\033[31m 输入有误，可执行 --help 查看帮助信息\033[0m"
	fi
	;;
cpu)
	if [ "$3" == "-a" ];then
		virsh setvcpus $2 $4 --live
	elif [ "$3" == "-c" ];then
		virsh setvcpus $2 $4 --live
		virsh setvcpus $2 $4 --config
	else
		echo -e "\033[31m 输入有误，可执行 --help 查看帮助信息\033[0m"
	fi
	;;
mem)
	if [ "$3" == "-a" ];then
		virsh setmem $2 $4
	elif [ "$3" == "-c" ];then
		virsh setmem $2 $4
		virsh setmem $2 $4 --config
	else
		echo -e "\033[31m 输入有误，可执行 --help 查看帮助信息\033[0m"
	fi
	;;
clone)
		U=`openssl rand -hex 4`-`openssl rand -hex 2`-`openssl rand -hex 2`-`openssl rand -hex 2`-`openssl rand -hex 6`
		M=`openssl rand -hex 1`:`openssl rand -hex 1`:`openssl rand -hex 1`:`openssl rand -hex 1`:`openssl rand -hex 1`:`openssl rand -hex 1`
		virsh destroy $2 &>/dev/null
		qemu-img  create   -f qcow2   -b  /var/lib/libvirt/images/$2.qcow2   /var/lib/libvirt/images/$3.qcow2 &>/dev/null
		cp /etc/libvirt/qemu/$2.xml /etc/libvirt/qemu/$3.xml
		sed -r -i "s/(<uuid>)(.*)(<\/uuid>)/\1$U\3/" /etc/libvirt/qemu/$3.xml
		sed -r -i "s/$2/$3/g" /etc/libvirt/qemu/$3.xml
		sed -r -i "s/(mac address=')(.*)('\/>)/\1$M\3/" /etc/libvirt/qemu/$3.xml
		virsh define /etc/libvirt/qemu/$3.xml
	;;
kz)
	if [ "$3" == "-a" ];then
		virsh snapshot-create-as $2 $4
	elif [ "$3" == "-l" ];then
		virsh snapshot-list $2
	elif [ "$3" == "-r" ];then
		virsh destroy $2 &>/dev/null
		virsh snapshot-revert $2 $4
	elif [ "$3" == "-d" ];then
		virsh snapshot-delete $2 $4
	else
		echo -e "\033[31m 输入有误，可执行 --help 查看帮助信息\033[0m"
	fi
	;;
-d)
	virsh destroy $2 &>/dev/null
	virsh undefine $2
	rm -rf /var/lib/libvirt/images/$2.qcow2
	;;
-s)
	echo -e "\033[35m1.虚拟机信息	2.磁盘	3.配置文件	4.快照	5.网卡\033[0m"
	read -p "输入您需要查询信息的编号:" num
	[ "$num" == "1" ]&& virsh dominfo $2
	[ "$num" == "2" ]&& virsh domblklist $2
	[ "$num" == "3" ]&& virsh dumpxml $2
	[ "$num" == "4" ]&& virsh snapshot-list $2
	[ "$num" == "5" ]&& virsh domiflist $2
	;;
--help|*)
	echo -e "\033[34m临时添加/删除磁盘:	disk domain -a/-d 磁盘名 磁盘大小\033[0m"
	echo -e "\033[36m临时添加/删除/永久网卡:	net domain -a/-d/-c \033[0m"
	echo -e "\033[34m临时/永久cpu:		cpu domain -a/-c cpu总数\033[0m"
	echo -e "\033[36m临时/永久内存		mem domain -a/-c 内存大小\033[0m"
	echo -e "\033[34m克隆虚拟机:		clone 源虚拟机 新克隆机\033[0m"
	echo -e "\033[36m增/删/恢快照:		kz domain -a/-d/-r 快照名\033[0m"
	echo -e "\033[34m查询设备信息:		-s domain\033[0m"
	echo -e "\033[36m删除克隆机:		-d domain\033[0m"
	;;
esac
