New-IscsiTargetPortal -TargetPortalAddress 172.20.0.61 -InitiatorPortalAddress (Get-NetIPAddress | Where-Object {$_.ipaddress -like "172.20.0.*"}).ipaddress
New-IscsiTargetPortal -TargetPortalAddress 172.20.1.61 -InitiatorPortalAddress (Get-NetIPAddress | Where-Object {$_.ipaddress -like "172.20.1.*"}).ipaddress
New-IscsiTargetPortal -TargetPortalAddress 172.20.0.62 -InitiatorPortalAddress (Get-NetIPAddress | Where-Object {$_.ipaddress -like "172.20.0.*"}).ipaddress
New-IscsiTargetPortal -TargetPortalAddress 172.20.1.62 -InitiatorPortalAddress (Get-NetIPAddress | Where-Object {$_.ipaddress -like "172.20.1.*"}).ipaddress

Connect-IscsiTarget -TargetPortalAddress 172.20.0.61 -InitiatorPortalAddress (Get-NetIPAddress | Where-Object {$_.ipaddress -like "172.20.0.*"}).ipaddress -IsPersistent:$true -IsMultipathEnabled:$true -NodeAddress iqn.1992-08.com.netapp:sn.1873898682
Connect-IscsiTarget -TargetPortalAddress 172.20.0.62 -InitiatorPortalAddress (Get-NetIPAddress | Where-Object {$_.ipaddress -like "172.20.0.*"}).ipaddress -IsPersistent:$true -IsMultipathEnabled:$true -NodeAddress iqn.1992-08.com.netapp:sn.1873909661
Connect-IscsiTarget -TargetPortalAddress 172.20.1.61 -InitiatorPortalAddress (Get-NetIPAddress | Where-Object {$_.ipaddress -like "172.20.1.*"}).ipaddress -IsPersistent:$true -IsMultipathEnabled:$true -NodeAddress iqn.1992-08.com.netapp:sn.1873898682
Connect-IscsiTarget -TargetPortalAddress 172.20.1.62 -InitiatorPortalAddress (Get-NetIPAddress | Where-Object {$_.ipaddress -like "172.20.1.*"}).ipaddress -IsPersistent:$true -IsMultipathEnabled:$true -NodeAddress iqn.1992-08.com.netapp:sn.1873909661

