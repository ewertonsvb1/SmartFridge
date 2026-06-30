$ErrorActionPreference = 'Stop'

$base = 'https://smartfridge-backend-c27p.onrender.com'
$results = @()

function Add-Result($name, $ok, $detail) {
    $script:results += [pscustomobject]@{
        Test   = $name
        Ok     = $ok
        Detail = $detail
    }
}

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Path,
        [object]$Body = $null,
        [string]$Token = $null
    )

    $url = $base + $Path
    $headers = @{}
    if ($Token) {
        $headers['Authorization'] = "Bearer $Token"
    }

    $json = $null
    if ($null -ne $Body) {
        $json = ($Body | ConvertTo-Json -Depth 8 -Compress)
    }

    try {
        if ($null -ne $json) {
            $resp = Invoke-WebRequest -Uri $url -Method $Method -Headers $headers -ContentType 'application/json' -Body $json
        } else {
            $resp = Invoke-WebRequest -Uri $url -Method $Method -Headers $headers
        }
        $status = [int]$resp.StatusCode
        $raw = $resp.Content
    } catch {
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode.value__
            $stream = $_.Exception.Response.GetResponseStream()
            if ($stream) {
                $reader = New-Object IO.StreamReader($stream)
                $raw = $reader.ReadToEnd()
                $reader.Close()
            } else {
                $raw = ''
            }
        } else {
            throw
        }
    }

    $obj = $null
    if ($raw) {
        try {
            $obj = $raw | ConvertFrom-Json
        } catch {
        }
    }

    return [pscustomobject]@{
        Status = $status
        Raw    = $raw
        Obj    = $obj
    }
}

function Expect($name, $actual, $expected) {
    if ($actual -eq $expected) {
        Add-Result $name $true ("status=$actual")
    } else {
        Add-Result $name $false ("status=$actual, esperado=$expected")
    }
}

$email = "scan_$([Guid]::NewGuid().ToString('N').Substring(0, 10))@email.com"
$pass = '123456'

$r = Invoke-Api -Method 'POST' -Path '/auth/register' -Body @{ name = 'Scan User'; email = $email; password = $pass }
Expect 'auth.register' $r.Status 200
$token = if ($r.Obj) { $r.Obj.token } else { $null }
if ([string]::IsNullOrWhiteSpace($token)) {
    Add-Result 'auth.register.token' $false 'token ausente'
} else {
    Add-Result 'auth.register.token' $true 'token recebido'
}

$l = Invoke-Api -Method 'POST' -Path '/auth/login' -Body @{ email = $email; password = $pass }
Expect 'auth.login' $l.Status 200
if ($l.Obj -and $l.Obj.token) {
    $token = $l.Obj.token
    Add-Result 'auth.login.token' $true 'token recebido'
} else {
    Add-Result 'auth.login.token' $false 'token ausente'
}

$me = Invoke-Api -Method 'GET' -Path '/users/me' -Token $token
Expect 'users.me' $me.Status 200
if ($me.Obj -and $me.Obj.email -eq $email) {
    Add-Result 'users.me.email' $true $me.Obj.email
} else {
    Add-Result 'users.me.email' $false ("email retornado=$($me.Obj.email)")
}

$today = Get-Date
$prodOk = @{
    name = 'Arroz Scan'
    quantity = 2
    manufactureDate = $today.AddDays(-1).ToString('yyyy-MM-dd')
    expirationDate = $today.AddDays(20).ToString('yyyy-MM-dd')
}
$prodNear = @{
    name = 'Leite Scan'
    quantity = 1
    manufactureDate = $today.AddDays(-2).ToString('yyyy-MM-dd')
    expirationDate = $today.AddDays(2).ToString('yyyy-MM-dd')
}
$prodExpired = @{
    name = 'Iogurte Scan'
    quantity = 1
    manufactureDate = $today.AddDays(-12).ToString('yyyy-MM-dd')
    expirationDate = $today.AddDays(-1).ToString('yyyy-MM-dd')
}

$p1 = Invoke-Api -Method 'POST' -Path '/products' -Body $prodOk -Token $token
Expect 'products.create.ok' $p1.Status 201
$p2 = Invoke-Api -Method 'POST' -Path '/products' -Body $prodNear -Token $token
Expect 'products.create.near' $p2.Status 201
$p3 = Invoke-Api -Method 'POST' -Path '/products' -Body $prodExpired -Token $token
Expect 'products.create.expired' $p3.Status 201

$productId = $null
if ($p1.Obj -and $p1.Obj.id) {
    $productId = [int64]$p1.Obj.id
    Add-Result 'products.create.id' $true ("id=$productId")
} else {
    Add-Result 'products.create.id' $false 'id ausente no create'
}

$list = Invoke-Api -Method 'GET' -Path '/products?page=0&size=20' -Token $token
Expect 'products.list' $list.Status 200
$byName = Invoke-Api -Method 'GET' -Path '/products?name=Arroz' -Token $token
Expect 'products.list.filter.name' $byName.Status 200
$byStatus = Invoke-Api -Method 'GET' -Path '/products?status=EXPIRED' -Token $token
Expect 'products.list.filter.status' $byStatus.Status 200

if ($productId) {
    $getById = Invoke-Api -Method 'GET' -Path "/products/$productId" -Token $token
    Expect 'products.getById' $getById.Status 200

    $upd = Invoke-Api -Method 'PUT' -Path "/products/$productId" -Body @{
        name = 'Arroz Atualizado'
        quantity = 5
        manufactureDate = $today.AddDays(-1).ToString('yyyy-MM-dd')
        expirationDate = $today.AddDays(25).ToString('yyyy-MM-dd')
    } -Token $token
    Expect 'products.update' $upd.Status 200
}

$expired = Invoke-Api -Method 'GET' -Path '/products/expired' -Token $token
Expect 'products.expired' $expired.Status 200
$expiring = Invoke-Api -Method 'GET' -Path '/products/expiring?days=3' -Token $token
Expect 'products.expiring' $expiring.Status 200
$dash = Invoke-Api -Method 'GET' -Path '/products/dashboard' -Token $token
Expect 'products.dashboard' $dash.Status 200

$shopCreate = Invoke-Api -Method 'POST' -Path '/shopping-list' -Body @{ name = 'Cafe'; quantity = 2 } -Token $token
Expect 'shopping.create' $shopCreate.Status 201
$shopId = $null
if ($shopCreate.Obj -and $shopCreate.Obj.id) {
    $shopId = [int64]$shopCreate.Obj.id
    Add-Result 'shopping.create.id' $true ("id=$shopId")
} else {
    Add-Result 'shopping.create.id' $false 'id ausente no create'
}
$shopList = Invoke-Api -Method 'GET' -Path '/shopping-list' -Token $token
Expect 'shopping.list' $shopList.Status 200
if ($shopId) {
    $shopUpd = Invoke-Api -Method 'PUT' -Path "/shopping-list/$shopId" -Body @{ name = 'Cafe Extra Forte'; quantity = 3; checked = $true } -Token $token
    Expect 'shopping.update' $shopUpd.Status 200

    $shopDel = Invoke-Api -Method 'DELETE' -Path "/shopping-list/$shopId" -Token $token
    Expect 'shopping.delete' $shopDel.Status 204
}

if ($productId) {
    $del = Invoke-Api -Method 'DELETE' -Path "/products/$productId" -Token $token
    Expect 'products.delete' $del.Status 204

    $after = Invoke-Api -Method 'GET' -Path "/products/$productId" -Token $token
    Expect 'products.getById.afterDelete' $after.Status 404
}

$failed = $results | Where-Object { -not $_.Ok }
Write-Output '=== API TEST REPORT ==='
$results | ForEach-Object {
    $prefix = if ($_.Ok) { 'PASS' } else { 'FAIL' }
    Write-Output ("$prefix | $($_.Test) | $($_.Detail)")
}
Write-Output ("TOTAL=$($results.Count); FAIL=$($failed.Count)")

if ($failed.Count -gt 0) {
    exit 1
}

exit 0
