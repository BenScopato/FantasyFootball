param(

    [Parameter(Mandatory=$True,Position=1)]
    [int]$StartSeason,
    [Parameter(Mandatory=$True,Position=2)]
    [int]$EndSeason,
    [Parameter(Mandatory=$True,Position=3)]
    [int]$StartWeek,
    [Parameter(Mandatory=$True,Position=4)]
    [int]$EndWeek,
    [Parameter(Mandatory=$True,Position=5)]
    [string]$SavePath

)

function Get-FFDataRunningBacks {

    param(
    
        [int]$Week,
        [int]$Season
    
    )

    $result = (invoke-webrequest -Uri "http://sports.yahoo.com/nfl/stats/byposition?pos=RB&conference=NFL&year=season_$($Season)&timeframe=Week$($Week)&sort=610&old_category=RB")

    return $result
}

function Clean-FFDataRunningBacks {

    param(
    
        [Microsoft.PowerShell.Commands.HtmlWebResponseObject]$ScrapedHTML,
        [int]$Week,
        [int]$Season
    )

    $players=@()

    foreach ($p in ($ScrapedHTML.Allelements | ? {$_.class -eq "ysprow1" -or $_.class -eq "ysprow2"}).outerhtml) {
    
        $split = ($p.Replace("&nbsp;","").Replace("</TD>","").Replace("</A>","").Replace("</SPAN>","").Replace("N/A","0")).Split("<>")

        [string]$_name = $split[6].Substring(0,$split[6].Length-2)
        [string]$_team = $split[10].Substring(0,$split[10].Length-2)
        [int]$_season = $Season
        [int]$_wk = $Week
        [int]$_rush_att = $split[16].Substring(0,$split[16].Length-2)
        [int]$_rush_yds = $split[20].Substring(0,$split[20].Length-2)
        [float]$_rush_ypa = $split[22].Substring(0,$split[22].Length-2)
        [int]$_rush_lng = $split[24].Substring(0,$split[24].Length-2)
        [int]$_rush_td = $split[26].Substring(0,$split[26].Length-2)
        [int]$_rec_rec = $split[30].Substring(0,$split[30].Length-2)
        [int]$_rec_tgt = $split[32].Substring(0,$split[32].Length-2)
        [int]$_rec_yds = $split[34].Substring(0,$split[34].Length-2)
        [float]$_rec_ypr = $split[36].Substring(0,$split[36].Length-2)
        [int]$_rec_lng = $split[38].Substring(0,$split[38].Length-2)
        [int]$_rec_td = $split[40].Substring(0,$split[40].Length-2)
        [int]$_fum = $split[44].Substring(0,$split[44].Length-2)
        [int]$_fuml = $split[46].Substring(0,$split[46].Length-2)

        $properties = @{
    
            'ID'="$($_name.ToUpper().Replace(' ',''))$($_team)";
            'Name'=$_name;
            'Team'=$_team;
            'Season'=$_season;
            'Wk'=$_wk;
            'Rush_Att'=$_rush_att;
            'Rush_Yds'=$_rush_yds;
            'Rush_YPA'=$_rush_ypa;
            'Rush_Lng'=$_rush_lng;
            'Rush_TD'=$_rush_td;
            'Rec_Rec'=$_rec_rec;
            'Rec_Tgt'=$_rec_tgt;
            'Rec_Yds'=$_rec_yds;
            'Rec_YPR'=$_rec_ypr;
            'Rec_Lng'=$_rec_lng;
            'Rec_TD'=$_rec_td;
            'Fum'=$_fum;
            'FumL'=$_fuml
    
        }

        $obj = New-Object -TypeName PSObject -Property $properties
        $players += $obj
    
    }

    return $players
}

function Get-RBs {

    param(
    
        [int]$StartSeason,
        [int]$ThroughSeason,
        [int]$StartWeek,
        [int]$ThroughWeek,
        [string]$SavePath
    )

    $Week = $StartWeek
    $Season = $StartSeason

    $RBs=@()
    
    for ($Season; $Season -lt ($ThroughSeason+1); $Season++) {

        for ($Week; $Week -lt ($ThroughWeek+1); $Week++) {

            $Data = Get-FFDataRunningBacks -Week $Week -Season $Season
            $Cleaned = Clean-FFDataRunningBacks -ScrapedHTML $Data -Week $Week -Season $Season
            $RBs += $Cleaned
        }

        $Week = $StartWeek
    }

    $RBs | select ID,Name,Team,Season,Wk,Rush_Att,Rush_Yds,Rush_YPA,Rush_Lng,Rush_TD,Rec_Rec,Rec_Tgt,Rec_Yds,Rec_YPR,Rec_Lng,Rec_TD,Fum,FumL | Export-Csv -Path "$($SavePath)\AllRBs_Seasons$($StartSeason)-$($ThroughSeason)_Weeks$($StartWeek)-$($ThroughWeek).csv" -force -notypeinformation

}

Get-RBs -StartSeason $StartSeason -ThroughSeason $EndSeason -StartWeek $StartWeek -ThroughWeek $EndWeek -SavePath $SavePath