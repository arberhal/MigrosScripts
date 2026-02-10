$Current = Get-WinUserLanguageList

$Add = @("en-US","fr-FR")

foreach ($lang in $Add) {
    if ($Current.LanguageTag -notcontains $lang) {
        $Current.Add($lang)
    }
}

Set-WinUserLanguageList $Current -Force
