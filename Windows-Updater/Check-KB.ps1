param (
    # Parameter help description
    [Parameter(Mandatory = $true)]
    [String]$KB
)
If ((get-hotfix).HotfixID -contains $KB) {
    #successfully installed
    Exit 0
}
else {
    #failed to install
    Exit 1
}