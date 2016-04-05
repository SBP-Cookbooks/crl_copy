#
# Title: CRL_Copy_v3.ps1
# Date: 6/2/2014
# Author: Paul Fox (MCS)
# Copyright Microsoft Corporation @2014
#
# Description: This script monitors the remaining lifetime of a CRL, publishes a CRL to a UNC and\or NTFS location and sends notifications via SMTP and EventLog.
#              There are two input arguments:
#              "Monitor" - checks the "master" CRL and the CRL in CDP locations. If the NextUpdate time is within "threshold" an alert will be sent.
#              "Publish" - checks the status of the master CRL and copies the Master CRL to identified CDP locations if the CRL numbers do not match
#                        Master CRL and CDP push location must be file system paths (UNC and\or NTFS). The script validates that push was successful by comparing the hash
#                        values of the Master and CDP CRLs.
#              Settings are configured within the crl_config.xml file.
#              This script requires the PSPKI powershell module (http://pspki.codeplex.com/).
#              Load the PSCX powershell module for the get-hash commandlet (http://pscx.codeplex.com/). Make sure to follow the install instructions in the download's ReadMe.txt file.
#              If ran within the task scheduler using the "Publish" method make sure the process runs as local administrator so it can read CertSvc service status
#              and is given the right to "Logon as a batch job."
#
# For debug output type $debugpreference = "continue" at the powershell command prompt.
#
#
# Date: 6/4/2016
# Author: Stephen Hoekstra
#
# Modified script to take an XmlFile parameter and to push CRL to destination if missing.
#

param ($Action, $XmlFile = ' .\crl_config.xml')

if(!(Test-Path $XmlFile))
{
    Write-Host
    Write-Host -Foreground Red "$($XmlFile) not found - exiting..."
    Write-Host
    Break
}

if(!$Action -or (($Action -ne "publish") -and ($Action -ne "monitor")))
{
    write-host "Usage: ./crl_copy_v3.ps1 publish|monitor"
    write-host ""
    write-host "Example: to publish CRL to CDP locations specified in crl_config.xml"
    write-host "./crl_copy_v3.ps1 publish"
    write-host ""
    write-host "Example: to compare the `"master`" CRL to published CRLs in the CDP locations specified in crl_config.xml"
    write-host "./crl_copy_v3.ps1 monitor"
    exit
}

#
# Function:     Results
# Description:  Writes the $evtlog_string to the Application eventlog and sends
#               SMTP message to recipients if $SMTP = [bool]$true and $EventLevel <= SMTPThreshold
#
function results([string]$evt_string, [string]$evtlog_string, [int]$level, [string]$title, [bool]$sendsmtp, [string]$from, [array]$to, [string]$SmtpServer, [string]$SMTPThreshold, [bool]$published)
{
    write-debug "******** Inside results function ********"
    write-debug "SMTP = $sendsmtp"
    write-debug "EventLevel: $level"
    write-debug "SMTP threshold: $SMTPThreshold"
    write-debug "Published Notification: $published"

    # if eventlog does not exist create it (must run script as local administrator once to create)
    if(![system.diagnostics.eventlog]::sourceExists($EventSource))
    {
        $evtlog = [system.diagnostics.eventlog]::CreateEventSource($EventSource,"Application")
    }

    # set eventlog object
    $evtlog = new-object system.diagnostics.eventlog("application",".")
    $evtlog.source = $EventSource

    # write to eventlog
    $evtlog.writeEntry($evtlog_string, $level, $EventID)

    # send email if sendsmtp = TRUE and event level <= SMTPThreshold or Notify on Publish
    if($sendsmtp -and (($level -le $SMTPThreshold) -or $published))
    {
        write-debug "Sending SMTP"
        if($level -eq $EventHigh)
        {
            $SMTPPriority = "High"
        }
        else
        {
            $SMTPPriority = "Normal"
        }
        $messageParameters = @{
            Subject = $title
            From = $from
            To = $to
            SmtpServer = $SmtpServer
            Body = $evt_string | Out-String
            Priority = $SMTPPriority
        }
        Send-mailMessage @messageParameters -BodyAsHtml
    }
    else
    {
        write-debug "SMTP message not sent"
    }

    if($tmp_outfile)
    {
        foreach($file in $tmp_outfile)
        {
            $debug_out = "Outputing to: " + $file
            write-debug $debug_out
            $evt_string | Out-File $file
        }
    }
    else
    {
        write-debug "No output files specified"
    }
} # end results function

#
# Function: retrieve
# Description: Pulls the CRL based upon method
#
function retrieve([string]$name, [string]$method, [string]$path)
{
    $retrieved_crl = $null
    $debug_out = "Function: pulling CRL: " + $name + " Method: " + $method + " Path: " + $path
    write-debug $debug_out

    switch($method)
    {
        "file"
        {
            $retrieved_crl = Get-CRL ($path + $name)
        }
        "ldap"
        {
            $CRLNumber = 0
            $i = 0
            $found = [bool]$FALSE
            $tmp = $name.split(".")
            $name = $tmp[0]
            $domain = "LDAP://cn=cdp,cn=public key services,cn=services,cn=configuration," + $path
            $root = New-Object System.DirectoryServices.DirectoryEntry($domain)
            $query = New-Object System.DirectoryServices.DirectorySearcher($root)
            $strFilter = "(&(objectclass=cRLDistributionPoint)(cn=$name))"
            $query.Filter = $strFilter
            $query.SearchScope = "subtree"
            $query.PageSize = 1000
            $results = $query.FindAll()

            $debug_out = "LDAP: found " + $results.count + " CRLs"
            write-debug $debug_out
            if($results.count -gt 0)
            {
                # sometimes there might be multiple CRLs in the LDAP location
                # find the highest CRL number and return that one
                foreach($ldapcrl in $results)
                {
                    if($ldapcrl.Properties.certificaterevocationlist)
                    {
                        [byte[]]$lcrl = $ldapcrl.Properties["certificaterevocationlist"][0]
                        $crl = Get-CRL $lcrl
                        $CRLnumberTMP = $crl.GetCRLNumber()
                        if($CRLnumberTMP -ge $CRLNumber)
                        {
                        $CRLNumber = $CRLnumberTMP
                        $result_num = $i
                        $found = [bool]$TRUE
                    }
                    $i++
                    }
                } #end foreach
            } # if results > 0
            else
            {
            write-debug "No LDAP CRL found"
        }

            if($found)
            {
            [byte[]]$lcrl = $results[$result_num].Properties["certificaterevocationlist"][0]
            $retrieved_crl = Get-CRL $lcrl
        }
            else
            {
            $retrieved_crl = $null
        }
        }
        "www"
        {
            $web_client = New-Object System.Net.WebClient
            $retrieved_crl = Get-CRL $web_client.DownloadData($path + $name)
        }
        default
        {
            write-host "Unable to determine CRL pull method, must be `"www`", `"ldap`" or `"file`" "
            $evtlog_string = "Unable to determine CRL pull method, must be `"www`", `"ldap`" or `"file`" " + $newline
            $evt_string = $evt_string + "Unable to determine CRL pull method, must be `"www`", `"ldap`" or `"file`" " + $newline
        }
    }
    if($retrieved_crl)
    {
        $debug_out = "Pulled CRL CRLNumber: " + $retrieved_crl.GetCRLNumber() + $newline
        $debug_out = $debug_out + "Pulled CRL IssuerName: " + $retrieved_crl.Issuer + $newline
        $debug_out = $debug_out + "Pulled CRL ThisUpdate: " + $retrieved_crl.ThisUpdate.ToLocalTime() + $newline
        $debug_out = $debug_out + "Pulled CRL NextUpdate: " + $retrieved_crl.NextUpdate.ToLocalTime() + $newline
        $debug_out = $debug_out + "Pulled CRL NextCRLPublish: " + $retrieved_crl.GetNextPublish().ToLocalTime() + $newline
        write-debug $debug_out
        return $retrieved_crl
    }
    else
    {
        $debug_out = "ERROR: Could not fetch CRL " + $path + $name
        write-debug $debug_out
        return $null
    }
} # end of function retrieve

#
# MAIN
#
# Variables
#
[xml]$xmlconfigfile = get-content $XmlFile
$master_name = $xmlconfigfile.configuration.master_crl.name
$master_retrieval = $xmlconfigfile.configuration.master_crl.retrieval
$master_path = $xmlconfigfile.configuration.master_crl.path
$cdps = $xmlconfigfile.configuration.cdps.cdp
$SMTP = [bool]$xmlconfigfile.configuration.SMTP.send_SMTP
$SmtpServer = $xmlconfigfile.configuration.SMTP.SmtpServer
$from = $xmlconfigfile.configuration.SMTP.from
$to = ($xmlconfigfile.configuration.SMTP.to).split(",")
$published_notify = [bool]$xmlconfigfile.configuration.SMTP.published_notify
$notify_of_publish = [bool]$false
$title = $xmlconfigfile.configuration.SMTP.title
$SMTPThreshold = $xmlconfigfile.configuration.SMTP.SMTPThreshold
$EventSource = $xmlconfigfile.configuration.eventvwr.EventSource
$EventID = $xmlconfigfile.configuration.eventvwr.EventID
$EventHigh = $xmlconfigfile.configuration.eventvwr.EventHigh
$EventWarning = $xmlconfigfile.configuration.eventvwr.EventWarning
$EventInformation = $xmlconfigfile.configuration.eventvwr.EventInformation
$threshold = $xmlconfigfile.configuration.warnings.threshold
$threshold_unit = $xmlconfigfile.configuration.warnings.threshold_unit
$cluster = [bool]$xmlconfigfile.configuration.adcs.cluster
$publish_html = [bool]$xmlconfigfile.configuration.output.publish
$tmp_outfile = ($xmlconfigfile.configuration.output.outfile).split(",")
$newline = [System.Environment]::NewLine
$time = Get-Date
$EventLevel = $EventInformation

#
# Import the PSPKI module
#
Import-Module -Name PSPKI

#
# Build the output string header
#
$evt_string = "<Title>" + $title + " " + $time + "</Title>" + $newline
$evt_string = $evt_string + "<h1><b>" + $title + " " + $time + "</br></h1>" + $newline
$evt_string = $evt_string + "<pre>" + $newline
$evt_string = $evt_string + "CRL Name: " + $master_name + $newline
$evt_string = $evt_string + "Method: " + $Action  + $newline
$evt_string = $evt_string + "Warning threshold: " + $threshold + " " + $threshold_unit + "<br>" + $newline

#
# Eventlog string
#
$evtlog_string = $evtlog_string + "CRL Name: " + $master_name + $newline
$evtlog_string = $evtlog_string + "Method: " + $Action  + $newline
$evtlog_string = $evtlog_string + "Warning threshold: " + $threshold + " " + $threshold_unit + $newline

#
# If ran within the task scheduler, run with admin rights to read the service status
# Is certsrv running? Is it a clustered CA?
# If clustered and is not running, send an Informational message
#
$service = get-service | where-Object {$_.name -eq "certsvc"}
if (!($service.Status -eq "Running"))
{
    if($Cluster)
    {
        $evt_string = $evt_string + "Active Directory Certificate Services is not running on this node of the cluster<br>" + $newline
        $evt_string = $evt_string + "</pre>" + $newline
        $evtlog_string = $evtlog_string + "Active Directory Certificate Services is not running on this node of the cluster<br>" + $newline
        # don't write the HTML output files, the other node will write the files
        $tmp_outfile = $null
        results $evt_string $evtlog_string $EventInformation $title $SMTP $from $to $SmtpServer $SMTPThreshold $notify_of_publish
        write-debug "ADCS is not running. This is a clustered node. Exiting"
        exit
    }
    else
    {
        $evt_string = $evt_string + "<font color=`"red`">**** IMPORTANT **** IMPORTANT **** IMPORTANT ****</font><br>" +  $newline
        $evt_string = $evt_string + "Certsvc status is: " + $service.status + "<br>" + $newline
        $evt_string = $evt_string + "</pre>" + $newline
        $evtlog_string = $evtlog_string + "**** IMPORTANT **** IMPORTANT **** IMPORTANT ****" +  $newline
        $evtlog_string = $evtlog_string + "Certsvc status is: " + $service.status + $newline
        results $evt_string $evtlog_string $EventHigh $title $SMTP $from $to $SmtpServer $SMTPThreshold $notify_of_publish
        write-debug "ADCS is not running and not a clustered node. Not good."
        exit
    }
}
else
{
    write-debug "Certsvc is running. Continue."
}

#
# Build the output table
#
$evt_string = $evt_string + "<table border=`"1`">" + $newline
$evt_string = $evt_string + "<tr><td bgcolor=`"#6495ED`"><b> CRL </b></td>`
                                 <td bgcolor=`"#6495ED`"><b> Path </b></td>`
                                 <td bgcolor=`"#6495ED`"><b> Number </b></td>`
                                 <td bgcolor=`"#6495ED`"><b> <a title=`"When this CRL was published`" href=http://blogs.technet.com/b/pki/archive/2008/06/05/how-effectivedate-thisupdate-nextupdate-and-nextcrlpublish-are-calculated.aspx target=`"_blank`"> ThisUpate </a></b></td>`
                                 <td bgcolor=`"#6495ED`"><b> <a title=`"The CRL will expire at this time`" href=http://blogs.technet.com/b/pki/archive/2008/06/05/how-effectivedate-thisupdate-nextupdate-and-nextcrlpublish-are-calculated.aspx target=`"_blank`"> NextUpdate </a></b></td>`
                                 <td bgcolor=`"#6495ED`"><b> <a title=`"Time when the CA will publish the next CRL`" href=http://blogs.technet.com/b/pki/archive/2008/06/05/how-effectivedate-thisupdate-nextupdate-and-nextcrlpublish-are-calculated.aspx target=`"_blank`"> NextCRLPublish </a> </b></td>`
                                 <td bgcolor=`"#6495ED`"><b> Status </b></td>"
if($Action -eq "publish")
{
    $evt_string = $evt_string + "<td bgcolor=`"#6495ED`"><b> Published </b></td>"
}
$evt_string = $evt_string + "</tr>" + $newline

#
# Get the master CRL
#
write-debug "Pulling master CRL"
$master_crl = retrieve $master_name $master_retrieval $master_path
if($master_crl)
{
    $evt_string = $evt_string + "<tr><td> Master </td>"
    $evt_string = $evt_string + "<td> " + $master_path + " </td>"
    $evt_string = $evt_string + "<td> " + $master_crl.GetCRLNumber() + " </td>"
    $evt_string = $evt_string + "<td> " + $master_crl.ThisUpdate.ToLocalTime() + " </td>"
    $evt_string = $evt_string + "<td> " + $master_crl.NextUpdate.ToLocalTime() + " </td>"
    $evt_string = $evt_string + "<td> " + $master_crl.GetNextPublish().ToLocalTime() + " </td>"
}
else
{
    $EventLevel = $EventHigh
    $evt_string = $evt_string + "</table></br>" + $newline
    $evt_string = $evt_string + "<font color=`"red`">Unable to retrieve master crl: $master_path$master_name </font><br>" + $newline
    $evt_string = $evt_string + "</pre>" + $newline
    $evtlog_string = $evtlog_string + "Unable to retrieve master crl: $master_name" + $newline
    results $evt_string $evtlog_string $EventLevel $title $SMTP $from $to $SmtpServer $SMTPThreshold $notify_of_publish
    write-debug $evt_string
    exit
}

#
# It looks like IsCurrent method checks againt UTC time
# So reverting to compare with LocalTime
#
if($master_crl.NextUpdate.ToLocalTime() -gt $time)
{
    # determine if with in threshold warning window
    $delta = new-timespan $time $master_crl.NextUpdate.ToLocalTime()
    $measure = "Total"+$threshold_unit
    if($delta.$measure -gt $threshold)
    {
        $evt_string = $evt_string + "<td bgcolor=`"green`"> </td>"
        $evtlog_string = $evtlog_string + "Master CRL is current" + $newline
    }
    else
    {
        $evt_string = $evt_string + "<td bgcolor=`"yellow`"> </td>"
        $evtlog_string = $evtlog_string + "Master CRL is soon to expire and is below threshold level" + $newline
        $EventLevel = $EventWarning
    }
}
else
{
    $evt_string = $evt_string + "<td bgcolor=`"red`"> </td>"
    $evtlog_string = $evtlog_string + "Master CRL has expired" + $newline
    $EventLevel = $EventHigh
}
if($Action -eq "publish")
{
    $evt_string = $evt_string + "<td> </td>"
}
$evt_string = $evt_string + "</tr>" + $newline

#
# Pull CRLs from the CDPs
#
write-debug "Pulling CDP CRLs"
foreach($cdp in $cdps)
{
    $cdp_crl = $null
    $cdp_crl = retrieve $master_name $cdp.retrieval $cdp.retrieval_path
    $evt_string = $evt_string + "<tr><td> " + $cdp.name + " </td>"
    # if CDP is http then make an HREF
    if($cdp.retrieval -eq "www")
    {
        if($master_name -match " ")
        {
            $www_crl = $master_name.replace(" ","%20")
        }
        else
        {
            $www_crl = $master_name
        }
        $evt_string = $evt_string + "<td><a href=" + $cdp.retrieval_path + $www_crl + ">" + $cdp.retrieval_path + $www_crl +" </a></td>"
    }
    else
    {
        $evt_string = $evt_string + "<td> " + $cdp.retrieval_path + " </td>"
    }

    if($cdp_crl)
    {
        $evt_string = $evt_string + "<td> " + $cdp_crl.GetCRLNumber() + " </td>"
        $evt_string = $evt_string + "<td> " + $cdp_crl.ThisUpdate.ToLocalTime() + " </td>"
        $evt_string = $evt_string + "<td> " + $cdp_crl.NextUpdate.ToLocalTime() + " </td>"
        $evt_string = $evt_string + "<td> " + $cdp_crl.GetNextPublish().ToLocalTime() + " </td>"

        if($cdp_crl.NextUpdate.ToLocalTime() -gt $time)
        {
            # determine if with in threshold warning window
            $delta = new-timespan $time $cdp_crl.NextUpdate.ToLocalTime()
            $measure = "Total"+$threshold_unit
            if($delta.$measure -gt $threshold)
            {
                # if within threshold and the CRL numbers do not match set to orange
                if($cdp_crl.GetCRLNumber() -ne $master_crl.GetCRLNumber())
                {
                    $evt_string = $evt_string + "<td bgcolor=`"orange`"> </td>"
                    $evtlog_string = $evtlog_string + $cdp.name + " CRL number does not match master CRL" + $newline
                }
                else
                {
                    $evt_string = $evt_string + "<td bgcolor=`"green`"> </td>"
                    $evtlog_string = $evtlog_string + $cdp.name + " is current" + $newline
                }
            }
            else
            {
                # within the threshold window
                $evt_string = $evt_string + "<td bgcolor=`"yellow`"> </td>"
                $evtlog_string = $evtlog_string + $cdp.name + " is soon to expire and is below threshold level" + $newline
                if($EventLevel -gt $EventWarning){$EventLevel = $EventWarning}
            }
        }
        else
        {
            # expired
            $evt_string = $evt_string + "<td bgcolor=`"red`"> </td>"
            $evtlog_string = $evtlog_string + $cdp.name + " has expired" + $newline
            if($EventLevel -gt $EventHigh){$EventLevel = $EventHigh}
        }
    } # end $cdp_crl exists
    else
    {
        $EventLevel = $EventWarning
        $evt_string = $evt_string + "<td colspan=`"4`" font color=`"red`">Unable to retrieve crl</font></td>" + $newline
        $evt_string = $evt_string + "<td bgcolor=`"yellow`"> </td>"
        $evtlog_string = $evtlog_string + "Unable to retrieve crl: " + $cdp.retrieval_path + $master_name + $newline
    }

    if($Action -eq "publish")
    {
        if($cdp.push)
        {
            if($cdp_crl -ne $null)
            {
                # push master CRL out to location if master CRL # > CDP CRL #
                if($master_crl.GetCRLNumber() -gt $cdp_crl.GetCRLNumber())
                {
                    # only file copy at this time
                    write-debug "Master CRL is newer, pushing out"
                    $source_path = $master_path + $master_Name
                    $source = Get-Item $source_path
                    $dest_path = $cdp.push_path + $master_Name
                    Copy-Item $source $dest_path

                    # Compare the hash values of the master CRL to the copied CDP CRL
                    # If they do not equal alert via SMTP set event level to high
                    $master_hash = get-hash $source_path
                    write-debug $master_hash.HashString
                    $cdp_hash = get-hash $dest_path
                    write-debug $cdp_hash.HashString
                    if($master_hash.HashString -ne $cdp_hash.HashString)
                    {
                        $evt_string = $evt_string + "<td bgcolor=`"red`"> failed </td>"
                        $evtlog_string = $evtlog_string + "CRL publish to " + $cdp.name + " failed" + $newline
                        if($EventLevel -gt $EventHigh){$EventLevel = $EventHigh}
                    }
                    else
                    {
                        write-debug "Push succeeded"
                        $evt_string = $evt_string + "<td bgcolor=`"green`"> " + $time + " </td>"
                        $evtlog_string = $evtlog_string + "CRL publish to " + $cdp.name + " succeeded" + $newline
                        # determine if we need to send an SMTP message
                        if($published_notify)
                        {
                        $notify_of_publish = $published_notify
                    }
                    }
                } #end if master crl # > cdp crl #
                else
                {
                    $evt_string = $evt_string + "<td> </td>"
                }
            }
            else
            {
                # only file copy at this time
                write-debug "CRL not found, pushing out"
                $source_path = $master_path + $master_Name
                $source = Get-Item $source_path
                $dest_path = $cdp.push_path + $master_Name
                Copy-Item $source $dest_path

                # Compare the hash values of the master CRL to the copied CDP CRL
                # If they do not equal alert via SMTP set event level to high
                $master_hash = get-hash $source_path
                write-debug $master_hash.HashString
                $cdp_hash = get-hash $dest_path
                write-debug $cdp_hash.HashString
                if($master_hash.HashString -ne $cdp_hash.HashString)
                {
                    $evt_string = $evt_string + "<td bgcolor=`"red`"> failed </td>"
                    $evtlog_string = $evtlog_string + "CRL publish to " + $cdp.name + " failed" + $newline
                    if($EventLevel -gt $EventHigh){$EventLevel = $EventHigh}
                }
                else
                {
                    write-debug "Push succeeded"
                    $evt_string = $evt_string + "<td bgcolor=`"green`"> " + $time + " </td>"
                    $evtlog_string = $evtlog_string + "CRL publish to " + $cdp.name + " succeeded" + $newline
                    # determine if we need to send an SMTP message
                    if($published_notify)
                    {
                        $notify_of_publish = $published_notify
                    }
                }
            }
        } #end if $cdp.push = TRUE
        else
        {
            $evt_string = $evt_string + "<td> </td>"
        }
    } #end of if $Action = publish

    $evt_string = $evt_string + "</tr>" + $newline
    write-debug "----------------"
} #end of foreach $cdps

#
# Close up the table
#
$evt_string = $evt_string + "</table></br>" + $newline

#
# Send results
#
results $evt_string $evtlog_string $EventLevel $title $SMTP $from $to $SmtpServer $SMTPThreshold $notify_of_publish
