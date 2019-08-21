;Written by Gary Millar / NHS Ayrshire and Arran
#NoTrayIcon
#include <Date.au3>
#Include <File.au3>
#include <Array.au3>
#include <Inet.au3>

Opt("TrayMenuMode",1) ;0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return

#CS ###################################################################################################
	#####  Setup the RDNS.ini File to store the variables captured here                           #####
	#####  This must be created under a standard user account before elevation                    #####
#CE ###################################################################################################

FileDelete(@ScriptDir & "\RDNS.ini")

$RDNSFile = (@ScriptDir & "\RDNS.ini")

$file = FileOpen($RDNSFile , 1)

#CS ###################################################################################################
	#####  Get the Credentials from the PMS.ini file                                              #####
#CE ###################################################################################################

	$inipath = "***Path Windows Shared drive***"

	$ini = $inipath & "PMS.ini"

	$UN = IniRead( $ini, "Process", "Username", "NotFound")
	$PWD = IniRead( $ini, "Process", "Password", "NotFound")
	$Domain = IniRead( $ini, "Process", "Domain", "NotFound")
	$LSRUNASE = IniRead( $ini, "Process", "LSRUNASE", "NotFound")
	$DomainSuffix = IniRead( $ini, "Process", "DomainSuffix", "NotFound")

#CS ###################################################################################################
	#####  Capture the HKCU VM Registry Settings                                                  #####
#CE ###################################################################################################

	$PhysicalMachineName = RegRead("HKEY_CURRENT_USER\Volatile Environment", "ViewClient_Machine_Name")

	$PhysicalMachineDomain = RegRead("HKEY_CURRENT_USER\Volatile Environment", "ViewClient_Machine_Domain")

#CS ###################################################################################################
	#####  This section amends the domain name for machines                                       #####
	#####  It covers situations where all the View desktops are provisioned on one domain         #####
	#####  but you have physical client machines on multiple separate domains                     #####
#CE ###################################################################################################

	Select
		Case $PhysicalMachineDomain = "(none)" ;Change to [TargetDomain] Dumb Terminal will display (None)
			 $PhysicalMachineDomain = "TargetDomain"

		Case $PhysicalMachineDomain = "Domain1" ;friendly Name
			 $PhysicalMachineDomain = "DM1"

		Case $PhysicalMachineDomain = "Domain2" ;friendly Name
			 $PhysicalMachineDomain = "DM2"

		Case $PhysicalMachineDomain = "Domain3" ;friendly Name
			 $PhysicalMachineDomain = "DM3"

		Case $PhysicalMachineDomain = "DM1" ;Do nothing

		Case $PhysicalMachineDomain = "DM2" ;Do nothing

		Case $PhysicalMachineDomain = "DM3" ;Do nothing

		Case $PhysicalMachineDomain = "DM1.FQ.DN" ;Split out just the first part
			 $PhysicalMachineDomain = "DM1"

		Case $PhysicalMachineDomain = "DM2.FQ.DN" ;Split out just the first part
			 $PhysicalMachineDomain = "DM2"

		Case $PhysicalMachineDomain = "DM3.FQ.DN" ;Split out just the first part
			 $PhysicalMachineDomain = "DM3"

		Case Else
			$PhysicalMachineDomain = "DM1"

	EndSelect

#CS ###################################################################################################
	#####  Capture Logon Server for possible future use                                           #####
#CE ###################################################################################################

	TCPStartup()

	$LogonServer = @LogonServer

	$LogonServer_Trim = StringMid($LogonServer, 3, 20)

	$LogonServer_tcpnametoip=TCPNameToIP($LogonServer_Trim)

	$LogonServer_tcpiptoname=_TCPIpToName($LogonServer_tcpnametoip)

	$LogonServer = $LogonServer_tcpiptoname

#CS ###################################################################################################
	#####  Populate the RDNS.ini file                                                             #####
#CE ###################################################################################################

	FileWrite($file, "[MachineName]" & @CRLF)

		FileWrite($file, "ViewClient_Machine_Name" & '=' & $PhysicalMachineName & @CRLF)
		FileWrite($file, @CRLF)

	FileWrite($file, "[DomainName]" & @CRLF)

		FileWrite($file, "ViewClient_Machine_Domain" & '=' & $PhysicalMachineDomain & @CRLF)
		FileWrite($file, @CRLF)

	FileWrite($file, "[FullyQualifiedDomainName]" & @CRLF)

		FileWrite($file, "FQDN" & '=' & $PhysicalMachineName & "." & $PhysicalMachineDomain & $DomainSuffix & @CRLF)
		FileWrite($file, @CRLF)

	FileWrite($file, "[LogonServerName]" & @CRLF)

		FileWrite($file, "Logon_Server_Name" & "=" & $LogonServer_tcpiptoname & @CRLF)

#CS ###################################################################################################
	######  Start Script and Create Logfile                                                       #####
#CE ###################################################################################################

	$Run_DNSCMD = @ScriptDir & "\launch_dnscmd.exe"
	Runwait(@ComSpec & ' /c ' & $LSRUNASE & ' /user:' & $UN & ' /password:' & $PWD & ' /domain:' & $Domain & ' /command:' & $Run_DNSCMD & ' /runpath:C:\' , "", @SW_HIDE)

#CS ###################################################################################################
	#####  End of Script                                                                          #####
#CE ###################################################################################################