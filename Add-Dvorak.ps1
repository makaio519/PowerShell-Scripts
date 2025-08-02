# Add United States-Dvorak Keyboard Layout 

$userLangList = Get-WinUserLanguagelist

# Add en-US if missing 
if (-not ($userLangList | Where-Object { $_.LanguageTag -eq "en-US})) {
	$userLangList.Add("en-US")
}

# Set the en-US input method to Dvorak
foreach ($lang in $userLangList) {
	if ($lang.LanguageTag -eq "en-US") {
		$lang.InputMethodTips.Add("0409:00000409")
		$lang.InputMethodTips.Add("0409:00010409")
	}
}

# Apply the settings
Set-WinUserLanguagelist $userLangList -Force
