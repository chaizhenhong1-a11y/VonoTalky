param(
  [string]$ProjectRoot = "C:\flutter project\vonotalky"
)

$ErrorActionPreference = 'Stop'

$path = Join-Path $ProjectRoot 'lib\features\contacts\presentation\pages\contact_detail_page.dart'
if (-not (Test-Path $path)) {
  throw "Missing file: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

$serviceImport = "import '../../../profile/data/services/profile_pet_showcase_service.dart';"
$widgetImport = "import '../../../profile/presentation/widgets/profile_pet_showcase.dart';"

if (-not $content.Contains($serviceImport)) {
  $anchor = "import '../../data/services/contact_detail_service.dart';"
  if (-not $content.Contains($anchor)) {
    throw 'Could not find ContactDetailPage import anchor.'
  }
  $content = $content.Replace(
    $anchor,
    "$anchor`r`n$serviceImport`r`n$widgetImport"
  )
}

if (-not $content.Contains('ProfilePetShowcaseService _petShowcaseService')) {
  $anchor = 'final ContactDetailService _service = ContactDetailService();'
  if (-not $content.Contains($anchor)) {
    throw 'Could not find ContactDetailService field anchor.'
  }
  $content = $content.Replace(
    $anchor,
    "$anchor`r`n  final ProfilePetShowcaseService _petShowcaseService =`r`n      ProfilePetShowcaseService();"
  )
}

if (-not $content.Contains('stream: _petShowcaseService.watchUserShowcase(current.uid)')) {
  $anchor = @'
                      _InfoCard(user: current),
                      const SizedBox(height: 16),
'@
  if (-not $content.Contains($anchor)) {
    throw 'Could not find ContactDetailPage info-card insertion point.'
  }

  $block = @'
                      _InfoCard(user: current),
                      const SizedBox(height: 16),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _petShowcaseService.watchUserShowcase(
                          current.uid,
                        ),
                        builder: (context, petShowcaseSnapshot) {
                          final pets = petShowcaseSnapshot.data ??
                              const <Map<String, dynamic>>[];
                          if (pets.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              ProfilePetShowcase(
                                pets: pets,
                                compact: true,
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
'@
  $content = $content.Replace($anchor, $block)
}

[IO.File]::WriteAllText(
  $path,
  $content,
  [Text.UTF8Encoding]::new($false)
)

Write-Host 'Public pet showcase added to ContactDetailPage.' -ForegroundColor Green
