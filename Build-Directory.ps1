# Employee directory generation script

# Create filename variables to save headache
$All = '\\pathtofile\empdir\All.txt'
$EmpDir = '\\pathtofile\empdir\employeedirectory.html'

# Clear old content to avoid duplicate entries
Clear-Content $All

# Collect all employees and sort alphabetically by surname
# You do not need to use the description attribute as a filter, but it is included as an example
# Update the Searchbase to reflect where you want to look for users
(Get-ADUser -Filter 'description -like "(placeholder)"' -Searchbase "OU=Users,DC=yourdomain,DC=local" -Properties sn,samaccountname | Sort-Object sn | Select-Object -Property samaccountname | Format-Table -HideTableHeaders | Out-File $All)

# These two lines clean up white space that would otherwise make the $All text file unuseable
(Get-Content $All) | Foreach-Object { $_ -replace ' ', ''} | Out-File $All
(Get-Content $All) | ? {$_.trim() -ne ""} | Set-Content $All

# Gather photos - photoless employees will show up with a broken image, so you may want to use a placeholder picture
$list = (Get-ADUser -Filter * -Properties thumbnailPhoto)
    ForEach ($User in $list){
        $Directory = '\\pathtofile\empdir\images\'
        If ($User.thumbnailphoto){
        $Filename = $Directory+$User.samaccountname+'.jpg'
        [System.Io.File]::WriteAllBytes($Filename, $User.thumbnailPhoto)
        }
    }

# Clear old content and start to build the HTML
Clear-Content $EmpDir

# Page header and the columns for the table are in this block. Edit with care.
Add-Content $EmpDir -Value "<!DOCTYPE html><html><link href=`"empdir.css`" type=`"text/css`" rel=`"stylesheet`"><body><h1>Employee Directory</h1><table><tr><th>Photo</th><th>Last Name</th><th>First Name</th><th>Title</th><th>Department</th><th>Extension</th><th>Email</th></tr>"

# This block builds out a table row for each user in the $All file
$FullList = (Get-Content $All)
    ForEach($person in $FullList){

        $LastName = (Get-ADUser -Filter "samaccountname -eq '$person'" -Property sn).sn
        $FirstName = (Get-ADUser -Filter "samaccountname -eq '$person'" -Property givenName).givenName
        $Title = (Get-ADUser -Filter "samaccountname -eq '$person'" -Property title).title
        $Department = (Get-ADUser -Filter "samaccountname -eq '$person'" -Property department).department
        $Extension = (Get-ADUser -Filter "samaccountname -eq '$person'" -Property telephoneNumber).telephoneNumber
        $Email = (Get-ADUser -Filter "samaccountname -eq '$person'" -Property mail).mail
    
        Add-Content $EmpDir -Value "<tr><td><img src=`".\\images\\$person.jpg`"></td><td>$LastName</td><td>$FirstName</td><td>$Title</td><td>$Department</td><td>$Extension</td><td><a href=`"mailto:$Email`">$Email</a></td></tr>"
    }

# End table and finish html
Add-Content $EmpDir -Value '</table></body></html>'
