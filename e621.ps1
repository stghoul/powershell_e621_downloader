
# Maximum simultanious downloads
$MaxThreads = 5

#
#
# Static tags

# always add theese:
$include_tags = @(
'female'
)

# always exclude theese
$exclude_tags = @(
'my_little_pony'
'sonic_the_hedgehog_(series)'
'my_hero_academia'
'3d'
'friendship_is_magic'
'obese_female'
'overweight'
'obese'
'vore'
)

#
#
#


###########################
# Done with preparations. #
# Script body goes there. #
###########################



$base_url = 'https://e621.net'
write-host "paste link or tags here"
$pasted_uri = Read-Host

$caption = " "    
$message = "Include static tags?"
[int]$defaultChoice = 0
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$do_include_tags = $host.ui.PromptForChoice($caption,$message, $options,$defaultChoice)

if ($pasted_uri -match "http") {
	$tags = @(
		(($pasted_url -split '=')[-1]) -split '\+'
	)
} else {
	$tags = @(
		$pasted_url -split ' '
	)
}

if ($do_include_tags -eq 0) {
	$tags += $include_tags
	foreach ($tag in $exclude_tags) {
		$tags += "-$tag"
	}
}

$search_url = $base_url + "/posts?tags="
foreach ($tag in $tags) {
	$search_url += "+" + $tag
}

$url = @{
	url = $search_url
	tags = $tags
}


write-host "-------------------------------"
write-host "Phase 1: collecting information"
write-host "-------------------------------"

$a = Invoke-WebRequest -Uri $url.url -UseBasicParsing



#Получаем ссылку последней страницы
$b = @()
$c = @()
$b = ($a.links | where {$_.href -match 'page\=\d'}).href
foreach ($i in $b) {
	$c += ((($i -split '&')[0]) -split '=')[1]
}
$b = @()
foreach ($i in $c) {$b += [int]$i}
$last_page = ($b | Sort-Object)[-1]

# получаем списоке тегов
$tags = ($pasted_uri -split '=')[-1]
Write-Host "Tags:"
$url.tags
Write-Host "Found $last_page pages"


#Далее, для каждой страницы получаем список страниц с постами
write-host "-----------------------------------------------"
write-host "Phase 2: Rolling through pages, gathering links"
write-host "-----------------------------------------------"
$d = @()
foreach ($i in 1..$last_page) {
	Write-Host -NoNewLine "`rWorking on page $i of $last_page"
	$request = $url.url + "&page=" + $i
	#$uri = "https://e621.net/posts?page=" + $i + "&tags=" + $tags
	$e = Invoke-WebRequest -Uri $request -UseBasicParsing
	$d += ($e.links | where {$_.href -match '\/posts\/\d'}).href
}

$links_count = $d.count
Write-Host "`rFinished $last_page pages                            "
Write-Host "Collected links for $links_count images"


# теперь для каждого поста сохраняем картинку
write-host "-------------------------"
write-host "Phase 3: Saving Images..."
write-host "-------------------------"

$counter = 0

foreach ($i in $d) {
	$counter++
    While ($(Get-Job -state running).count -ge $MaxThreads){
        Start-Sleep -m 250
    }
	Get-Job -state Completed | Remove-Job
	
	$arg = @{
		base_url = $base_url
		url = $i
		local_path = $PSScriptRoot
	}
	
	Write-Host -NoNewLine "`rDownloading $counter image of $links_count"
	
	Start-Job -ScriptBlock {
		
		$base_url = $args.base_url
		$url = $args.url
		$local_path = $args.local_path
		
		
		$page_url = "$base_url" + "$url"
		$f = Invoke-WebRequest -Uri $page_url  -UseBasicParsing
		$img = ($f.links.href -match '^https:\/\/static\d.e621.net')[0]
		$filename = ($img -split  -split '/')[-1]
		$local_file = "$local_path" + "\" + "$filename"
		Invoke-WebRequest $img -OutFile $local_file  -UseBasicParsing
		write-host "page_url = $page_url"
		write-host "img = $img"
		write-host "local_file = $local_file"
	} -ArgumentList $arg | Out-Null
}

Write-Host "`rJust a few more seconds...                                     "
Get-Job | Wait-Job
Write-Host "`rDone"
