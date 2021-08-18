# Disclaimer: this script works with e621 site, which is strictly 18+

# What is it
It is a powershell script to download content from e621 site.

### Pros and cons
#### Pros
+ It is powershell. You can simply modify script for your needs.
+ It dont require any additional modules and works on any version of powershell.
+ It have static filters, that you, of course, can edit.
#### Cons
+ It downloads images to the same folder, where script is located. It can be easily fixed. May be, next version.

### How to config
#### First of all, edit script config.
Open script in a text editor (notepad, for example).
In the top part you will see next variables:

```
$MaxThreads = 5
```
This is maximum amount of simultanious downloads.
You can increase or decrease it, depends on your CPU and internet connection speed.
Also, dont increase it very much, or you can get banned.

Next, what I call, static tags:
```
$include_tags = @(
'some_good_tags'
)

$exclude_tags = @(
'some_ugly_things'
)
```
Theese tags will be included of excluded from search request.
Dont forget about quotemarks.

Thats it, after you edit theese, script is ready to use.


Script goes in two version - base version and "big load" version.
If your search request finds just a few pages (something like less then 20 pages), you can use base version.
It's pretty straight-forward and will download all content in a reasonable time.
If you have a lot of pages to download, better use big load version.

# How to use base version
For example, you want to download animal crossing characters without panties.
Just copy script into separate folder, where you want to download lewds and launch it.
Then, paste a whole url 'https://e621.net/posts?tags=bottomless+animal_crossing' or just tags 'bottomless animal_crossing' (without quotemarks).
After that, script will ask you, should it include static tags to search request or not.
And thats it.

# How to use big load verion.
Big load works almost the same, as a base version.
Basically, it separates on a two parts - 
first, script will collect all links and save it to a text files
second, it will download content from the saved links.

And while downloading, you can press 'Q' to pause it.
Then script will finish downloading all files from current file and stop.