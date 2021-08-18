
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

# Maximum saved links per file.
$max_links_per_file = 100

###########################
# Done with preparations. #
# Script body goes there. #
###########################





$base_url = 'https://e621.net'

function parse_url {
	param (
		$pasted_url
	)
	
	$caption = " "    
	$message = "Include static tags?"
	[int]$defaultChoice = 0
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$do_include_tags = $host.ui.PromptForChoice($caption,$message, $options,$defaultChoice)
	
	#remove-variable caption, message, yes, no, options
	
	if ($page_url -match "http") {
		$tags = @(
			(($pasted_url -split '=')[-1]) -split '\+'
		)
	} else {
		$tags = @(
			$pasted_url -split ' '
		)
	}
	
	if ($do_include_tags -eq 0) {
		$tags += $script:include_tags
		foreach ($tag in $script:exclude_tags) {
			$tags += "-$tag"
		}
	}
	
	$url = $script:base_url + "/posts?tags="
	foreach ($tag in $tags) {
		$url += "+" + $tag
	}
	
	$ret = @{
		url = $url
		tags = $tags
	}
	
	return $ret
}


function get_links {
	
	write-host "paste link of tags here"
	$pasted_url = Read-Host
	
	$url = parse_url $pasted_url
	
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
	#$tags = ($pasted_url -split '=')[-1]
	Write-Host "Tags:"
	#$url:tags -split "\+"
	$url.tags
	Write-Host ""
	Write-Host "Found $last_page pages"
	
	
	#Далее, для каждой страницы получаем список страниц с постами
	write-host "-----------------------------------------------"
	write-host "Phase 2: Rolling through pages, gathering links"
	write-host "-----------------------------------------------"
	$d = @()
	foreach ($i in 1..$last_page) {
		Write-Host -NoNewLine "`rWorking on page $i of $last_page"
		$request = $url.url + "&page=" + $i
		$e = Invoke-WebRequest -Uri $request -UseBasicParsing
		$d += ($e.links | where {$_.href -match '\/posts\/\d'}).href
	}

	$links_count = $d.count
	Write-Host "`rFinished $last_page pages                            "
	Write-Host "Collected links for $links_count images"

	Write-Host "Saving links to files"
	$file_number = 1
	$counter = 0

	foreach ($i in $d) {
		$counter++
		if ($counter -eq $script:max_links_per_file) {
			$counter = 0
			$file_number++
		}
		$file_name = "e621_$file_number.txt"
		$i >> $file_name
	}
}

function download_images {
	write-host "-------------------------"
	write-host "Phase 3: Saving Images..."
	write-host "Press Q to exit"
	write-host "-------------------------"
	
	while (Test-Path -path 'e621*.txt') {
		$counter = 0
		$lists_left = (Get-ChildItem -Filter 'e621*.txt').count
		#Write-Host "`rLists left: $lists_left                                "
		$d = get-content (Get-ChildItem -Filter 'e621*.txt')[0]
		$links_count = $d.count
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
			
			Write-Host -NoNewLine "`rPages left: $lists_left, Downloading image $counter of $links_count"
			
			Start-Job -ScriptBlock {
				
				$base_url = $args.base_url
				$url = $args.url
				$local_path = $args.local_path
				
				
				$page_url = "$base_url" + "$url"
				$f = Invoke-WebRequest -Uri $page_url -UseBasicParsing
				$img = ($f.links.href -match '^https:\/\/static\d.e621.net')[0]
				$filename = ($img -split  -split '/')[-1]
				$local_file = "$local_path" + "\" + "$filename"
				Invoke-WebRequest $img -OutFile $local_file -UseBasicParsing
				write-host "page_url = $page_url"
				write-host "img = $img"
				write-host "local_file = $local_file"
			} -ArgumentList $arg | Out-Null
		}

		Write-Host -NoNewLine "`rJust a few more seconds...                                               "
		Get-Job | Wait-Job -Timeout 600 | out-null
		Get-Job -state running | Stop-Job -PassThru
		Remove-Item (Get-ChildItem -Filter 'e621*.txt')[0]
		if ([Console]::KeyAvailable) {
			$key = [Console]::ReadKey($true)
			if ($key.key -eq "q") { 
				Write-Output "You pressed 'q' to stop stop downloading"
				break # you need a break here to get out of the loop
			}
		}
	}
}

function Show-Menu {
    param (
        [string]$Title = 'Download lewds'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Get Links"
    Write-Host "2: Download"
    Write-Host "Q: Quit"
  Write-Host " "
}


while ($true) {
  Show-Menu
  $selection = Read-Host "Selection:"
  switch ($selection) {
    '1' {
      get_links
    } '2' {
      download_images
    } 'q' {
      exit 0
    }
  }
}
