# PowerShell code
########################################################
# Log in to Azure with AZ (standard code)
########################################################
Write-Verbose -Message 'Connecting to Azure'

# Name of the Azure Run As connection
$ConnectionName = 'AzureRunAsConnection'
try
{
    # Get the connection properties
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName        
 
    'Log in to Azure...'
    $null = Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $ServicePrincipalConnection.TenantId `
        -ApplicationId $ServicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$ServicePrincipalConnection)
    {
        # You forgot to turn on 'Create Azure Run As account' 
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else
    {
        # Something else went wrong
        Write-Error -Message $_.Exception.Message
        throw $_.Exception
    }
}
########################################################

# Test code getting all resource groups

# PowerShell code
# Get all SQL Servers to check whether they host a Synapse SQL Pool
$allSqlServers = Get-AzSynapseWorkspace

# Loop through all SQL Servers
foreach ($sqlServer in $allSqlServers)
{
    # Log which SQL Servers are checked and in which resource group
    Write-Output "Checking Sypanpse workspace [$($sqlServer.name)] for Synapse SQL Pools"
    
    # Get all databases from a SQL Server, but filter on Edition = "DataWarehouse"
    $allSynapseSqlPools = Get-AzSynapseSqlPool -WorkspaceName $sqlServer.name
    # Loop through each found Synapse SQL Pool
    foreach ($synapseSqlPool in $allSynapseSqlPools)
    {
        # Show status of found Synapse SQL Pool
        # Available statuses: Online Paused Pausing Resuming
        Write-Output "Synapse SQL Pool [$($synapseSqlPool.SqlPoolName)] found with status [$($synapseSqlPool.Status)]"
        
        # If status is online then pause Synapse SQL Pool
        if ($synapseSqlPool.Status -eq "Online")
        {
            # Pause Synapse SQL Pool
            $startTimePause = Get-Date
            Write-Output "Pausing Synapse SQL Pool [$($synapseSqlPool.SqlPoolName)]"
            $resultsynapseSqlPool = $synapseSqlPool | Suspend-AzSynapseSqlPool

            # Show that the Synapse SQL Pool has been pause and how long it took
            $endTimePause = Get-Date
            $durationPause = NEW-TIMESPAN –Start $startTimePause –End $endTimePause
            $synapseSqlPool = Get-AzSynapseSqlPool -WorkspaceName $sqlServer.name
            Write-Output "Synapse SQL Pool [$($synapseSqlPool.SqlPoolName)] paused in $($durationPause.Hours) hours, $($durationPause.Minutes) minutes and  $($durationPause.Seconds) seconds. Current status [$($synapseSqlPool.Status)]"
        }
    }
}
