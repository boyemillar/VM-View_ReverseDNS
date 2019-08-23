;Written by Gary Millar / NHS Ayrshire and Arran
#NoTrayIcon
#include <Date.au3>
#Include <File.au3>
#include <Array.au3>
#include <Inet.au3>

Opt("TrayMenuMode",1) ;0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return

$sType=3

#CS ###################################################################################################
	#####  Setup the Log File                                                                     #####
#CE ###################################################################################################

	FileDelete(@ScriptDir & "\launch_dnscmd.log")

	$LogFile = (@ScriptDir & "\launch_dnscmd.log")
	$file = FileOpen($LogFile , 1)

	FileWrite($file, "###############################################################################################" & @CRLF)
	FileWrite($file, ">>>>> Start...    " & _NowTime($sType) & @CRLF)
	FileWrite($file, "###############################################################################################" & @CRLF & @CRLF)

#CS ###################################################################################################
	#####  Get the details from the ini file                                                      #####
#CE ###################################################################################################

	;Path to the remote ini file
	$remoteinipath = "***Path Windows Shared drive***"

	;Name of the remote ini file
	$remoteinifile = $remoteinipath & "Config.ini"

	;Domain suffix
	$DomainSuffix = IniRead( $remoteinifile, "DC", "DomainSuffix", "NotFound")

	;Name of the Domain controller to update DNS (Best to be the Primary Domain Controller)
	$DNSServer = IniRead( $remoteinifile, "DC", "DomainController", "NotFound")

#CS ###################################################################################################
	#####  Create an Array based on the IP Address Segments                                       #####
#CE ###################################################################################################

	Local $hostname=@ComputerName

	TCPStartup()

	$tcpnametoip=TCPNameToIP($hostname)
	$tcpiptoname=_TCPIpToName($tcpnametoip)

	$array = StringSplit ( $tcpnametoip, ".")

#CS ###################################################################################################
	#####  Create the Virtual Machine Vars                                                        #####
#CE ###################################################################################################

	FileWrite($file, "###############################################################################################" & @CRLF)
	FileWrite($file, ">>>>> Get VM Variables...    " & @CRLF)
	FileWrite($file, "###############################################################################################" & @CRLF & @CRLF)

	;Read the segments from the IP address captured above
	$VMIPAddress = $array[1] & '.' & $array[2] & '.' & $array[3] & '.' & $array[4]
		FileWrite($file, "VM IP Address = " & $VMIPAddress & @CRLF)

	;Turn the segments around to create the reversed IP address
	$VMReverseDNSName = $array[4] & '.' & $array[3] & '.' & $array[2] & '.' & $array[1] & '.in-addr.arpa'
		FileWrite($file, "VM Reverse DNS Name = " & $VMReverseDNSName & @CRLF)

	;Create a variable to hold the Reverse DNS Zone
	$VMReverseDNSzone = $array[3] & '.' & $array[2] & '.' & $array[1] & '.in-addr.arpa'
		FileWrite($file, "VM Reverse DNS Zone = " & $VMReverseDNSzone & @CRLF & @CRLF)

#CS ###################################################################################################
	#####  Get Physical Machines Variables                                                        #####
#CE ###################################################################################################

	FileWrite($file, "###############################################################################################" & @CRLF)
	FileWrite($file, ">>>>> Get Physical Machine Variables...    " & @CRLF)
	FileWrite($file, "###############################################################################################" & @CRLF & @CRLF)

	$RegistryKeyFile = (@ScriptDir & "\RDNS.ini")

	$ViewClient_Machine_Name = IniRead( $RegistryKeyFile, "MachineName", "ViewClient_Machine_Name", "NotFound")
	$ViewClient_Machine_Domain = IniRead( $RegistryKeyFile, "DomainName", "ViewClient_Machine_Domain", "NotFound")
	$LogonServerName = IniRead( $RegistryKeyFile, "LogonServerName", "Logon_Server_Name", "NotFound")

	$PhysicalMachineName = $ViewClient_Machine_Name
		FileWrite($file, "Physical Machine Name = " & $PhysicalMachineName & @CRLF)
		ConsoleWrite($PhysicalMachineName & @CRLF)

	$PhysicalMachineDomain = $ViewClient_Machine_Domain
		FileWrite($file, "Physical Machine Domain = " & $PhysicalMachineDomain & @CRLF)
		ConsoleWrite($PhysicalMachineDomain & @CRLF)

	$FullyQualifiedDomainName = $PhysicalMachineName  & '.' & $PhysicalMachineDomain & $DomainSuffix
	ConsoleWrite($FullyQualifiedDomainName & @CRLF)

	$PhysicalMachineFQDN =  $FullyQualifiedDomainName
		FileWrite($file, "Physical Machine Fully Qualified Domain Name = " & $PhysicalMachineFQDN & @CRLF & @CRLF)
		ConsoleWrite($PhysicalMachineFQDN & @CRLF)

		FileWrite($file, "Logon Server Name = " & $LogonServerName & @CRLF & @CRLF)
		ConsoleWrite("Logon Server Name = " & $LogonServerName & @CRLF)

		FileWrite($file, "DNS Server being updated = " & $DNSServer & @CRLF & @CRLF)
		ConsoleWrite("DNS Server being updated = " & $DNSServer & @CRLF)

#CS ###################################################################################################
	#####  Setup DNSCMD command                                                                   #####
#CE ###################################################################################################

	FileWrite($file, "###############################################################################################" & @CRLF)
	FileWrite($file, ">>>>> Setup DNSCMD command...    " & @CRLF)
	FileWrite($file, "###############################################################################################" & @CRLF & @CRLF)

	$dnscmd = @SystemDir & "\dnscmd.exe"
	$recordName = $array[4]
	$recordType = "PTR"
	$recordAddress = $PhysicalMachineFQDN

	Runwait(@ComSpec & ' /c ' & $dnscmd & ' ' & $DNSServer & ' /RecordDelete ' & $VMReverseDNSzone & ' ' & $recordName & ' ' & $recordType & ' /f' , "", @SW_HIDE)
	ConsoleWrite($dnscmd & ' ' & $DNSServer & ' /RecordDelete ' & $VMReverseDNSzone & ' ' & $recordName & ' ' & $recordType & ' /f' & @CRLF)
	FileWrite($file, $dnscmd & ' ' & $DNSServer & ' /RecordDelete ' & $VMReverseDNSzone & ' ' & $recordName & ' ' & $recordType & ' /f' & @CRLF)

	Runwait(@ComSpec & ' /c ' & $dnscmd & ' ' & $DNSServer & ' /RecordAdd ' & $VMReverseDNSzone & ' ' & $recordName & ' ' & $recordType & ' ' & $recordAddress & ' ' , "", @SW_HIDE)
	ConsoleWrite($dnscmd & ' ' & $DNSServer & ' /RecordAdd ' & $VMReverseDNSzone & ' ' & $recordName & ' ' & $recordType & ' ' & $recordAddress & @CRLF)
	FileWrite($file, $dnscmd & ' ' & $DNSServer & ' /RecordAdd ' & $VMReverseDNSzone & ' ' & $recordName & ' ' & $recordType & ' ' & $recordAddress & @CRLF & @CRLF)


	FileWrite($file, "###############################################################################################" & @CRLF)
	FileWrite($file, ">>>>> End...    " & _NowTime($sType) & @CRLF)
	FileWrite($file, "###############################################################################################" & @CRLF & @CRLF)

#CS ###################################################################################################
	#####  End of Script                                                                          #####
#CE ###################################################################################################
