# Wow addons

## Install from new

`cd "C:\Program Files(x86)\World of Warcraft\_classic_\Interface\Addons\"`  
`rm -rdf *`  
`git init`  
`git remote add origin -t classic https://github.com/thakhisis/wow-addons`  
`git checkout classic`
`git pull`  

## Update from new
`cd "C:\Program Files(x86)\World of Warcraft\_classic_\Interface\Addons\"`  
`git init`  
`git remote add -t classic https://github.com/thakhisis/wow-addons`  
`git fetch`  
`git reset origin/master`  
`git checkout -t origin/master`  

## Update existing
`git add .`  
`git commit -m "update to addons"`
`git push`
