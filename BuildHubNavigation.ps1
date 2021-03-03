param([Parameter(Mandatory=$true)] [string] $HubUrl)
function Update-HubNavigation([string]$HubName, [string]$Url)
{
    Write-Host "Creating Navigation Hub: '$HubName' at $Url";
    Connect-PnPOnline -Url $Url -Interactive
    $site = Get-PnPSite -Includes Id, RootWeb,ServerRelativeUrl,IsHubSite;

    #region Term Groups
    $group = (Get-PnPTermGroup -Includes Id, Name -ErrorAction SilentlyContinue | ? { $_.Name -eq $HubName} )

    if(-not $group)
    {
        Write-Host "Creating Group: '$HubName'"
        $group = New-PnPTermGroup -Name $HubName
        Start-Sleep -s 2
    } else
    {
        Write-Host "Group: '$HubName' already exists";
    }
    #endregion

    #region Add Group Hierarchy

    # Create the main TermSet "Menu"

    $termSet = Get-PnPTermSet -Identity "Menu" -TermGroup $group -ErrorAction SilentlyContinue
    if(-not $termSet)
    {
        Write-Host "Creating 'Menu' TermSet"
        $termSet = New-PnPTermSet -Name "Menu" -TermGroup $group
        Start-Sleep -s 2
        Set-PnPTermSet -Identity "Menu" -TermGroup $group -UseForSiteNavigation $true
        Start-Sleep -s 2
    }
    
    $webs = Get-PnPSubWebs -Includes Id, ParentWeb,Webs, Title -IncludeRootWeb -Recurse
    foreach($web in $webs)
    {
        $Id = $web.Id;
        if($site.ServerRelativeUrl -eq $web.ServerRelativeUrl)
        {
            $Id = $site.Id
        }
        $parentId = $web.ParentWeb.Id;
        if($site.ServerRelativeUrl -eq $web.ParentWeb.ServerRelativeUrl)
        {
            $parentId = $site.Id;
        }        
        $term = $null;
        $term = Get-PnPTerm -Id $web.Id -TermSet $termSet -TermGroup $group -Includes LocalCustomProperties,Name, Id, Parent -ErrorAction SilentlyContinue

        if(-not $term.Id)
        {
            Write-Host "Creating Term '$($web.Title)'"
            if($web.ParentWeb.Id)
            {
                Write-Host "+++ Adding term to parent '$($web.ParentWeb.Title)'";
                $term = Add-PnPTermToTerm -ParentTermId $parentId -Name $web.Title -Id $Id -LocalCustomProperties @{ '_Sys_Nav_SimpleLinkUrl'=$web.ServerRelativeUrl; 
                                                                                                                     'SiteId'=$site.Id.ToString() }
            } else
            {
                $term = New-PnPTerm -Id $Id -Name $web.Title -TermSet $termSet -TermGroup $group -LocalCustomProperties @{ '_Sys_Nav_SimpleLinkUrl'=$web.ServerRelativeUrl ; 
                                                                                                                           'SiteId'=$site.Id.ToString() }
            }
            Start-Sleep -s 2
         }
    }
    Write-Host "Done for '$($web.Title)'..";
    #endregion

}



#region Load Module And Connect
if(-not (Get-Module PnP.PowerShell))
{
    Install-Module -Name PnP.PowerShell -AllowClobber -Scope CurrentUser -ErrorAction Stop
}
Import-Module Pnp.PowerShell
Connect-PnPOnline -Url $HubUrl -Interactive
#endregion

$hubs = Get-PnpHubSite


foreach($hub in $hubs)
{
    Write-Host "Working with hub '$($hub.Title)' at $($hub.SiteUrl)"
    Update-HubNavigation -HubName $hub.Title -Url $hub.SiteUrl
    $sites = Get-PnPHubSiteChild -Identity $hub.SiteUrl
    $sites | % { Update-HubNavigation -HubName $hub.Title -Url $_ }
}
