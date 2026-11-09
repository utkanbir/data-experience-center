import json, os, re
from datetime import datetime, timezone
from html import unescape
from pathlib import Path
from governance_client import Client, GovernanceError, pointer

METRICS = {'Sales.netRevenue', 'Sales.netLiters', 'Sales.averagePrice'}

def text(value):
    return re.sub(r'\s+', ' ', unescape(re.sub(r'<[^>]*>', ' ', str(value or '')))).strip()

def catalog(settings, client):
    metrics = settings.get('metrics', [])
    if len(metrics) != 3 or {m.get('metricId') for m in metrics} != METRICS:
        raise GovernanceError('Üç referans metriğinin açık CDGC → Cube eşlemesi gerekli.')
    if any(not m.get('assetId') for m in metrics):
        raise GovernanceError('Metrik kayıt eşlemeleri eksik; katalogdan hesap seçilemez.')
    technical = settings.get('technical', {})
    ids = [m['assetId'] for m in metrics]
    if technical.get('assetId'):
        ids.append(technical['assetId'])
    assets = client.assets(ids)
    tech = assets.get(technical.get('assetId'), {})
    glossary = pointer(tech, technical.get('glossaryPointer', '/glossary'))
    accepted = {g.get('core.identity') for g in glossary if isinstance(g, dict) and g.get('core.curationStatus') == 'ACCEPTED'} if isinstance(glossary, list) else set()
    output = []
    for m in metrics:
        row = assets.get(m['assetId'], {})
        summary = row.get('summary', {})
        description = text(summary.get('core.description'))
        owner = settings.get('owner', {})
        person = pointer(row, owner.get('idPointer', '/stakeholdership/0/core.identity'))
        role = pointer(row, owner.get('rolePointer', '/stakeholdership/0/core.role'))
        publication = settings.get('publication', {})
        lifecycle = pointer(row, publication.get('pointer', '/selfAttributes/core.assetLifecycle'))
        reasons = []
        if text(summary.get('core.name')).casefold() != text(m.get('expectedName')).casefold():
            reasons.append('Kayıt adı eşlemeyle uyuşmuyor veya kayıt okunamadı.')
        if not m.get('descriptionContains') or not all(text(term).casefold() in description.casefold() for term in m['descriptionContains']):
            reasons.append('İş tanımı beklenen açıklama ve birimleri karşılamıyor.')
        if not isinstance(person, str) or not person or not isinstance(role, str) or not role:
            reasons.append('Sahiplik kişi/rol kaydı doğrulanamadı; gelişmiş API yollarını kontrol et.')
        if owner.get('expectedId') and person != owner['expectedId']:
            reasons.append('Beklenen sorumlu ile katalogdaki sorumlu farklı.')
        if owner.get('expectedRoleId') and role != owner['expectedRoleId']:
            reasons.append('Beklenen sahiplik rolü farklı.')
        if lifecycle != publication.get('expected', 'Published'):
            reasons.append('Beklenen yayın durumu sağlanmıyor.')
        external = tech.get('core.externalId')
        if not technical.get('expectedExternalId') or external != technical['expectedExternalId'] or m['assetId'] not in accepted:
            reasons.append('Teknik kaynak kimliği ve ACCEPTED glossary bağı doğrulanamadı.')
        output.append({'assetId': m['assetId'], 'metricId': m['metricId'], 'name': text(summary.get('core.name')) or m['expectedName'], 'description': description, 'ownerId': person, 'ownerRoleId': role, 'lifecycle': lifecycle, 'technicalExternalId': external, 'queryable': not reasons, 'reasons': reasons, 'observedAt': datetime.now(timezone.utc).isoformat()})
    return output

def load_catalog():
    directory = Path(os.environ.get('GOVERNANCE_DIR', '/governance'))
    mode = directory / 'connection-mode.txt'
    if mode.exists() and mode.read_text().strip() == 'later':
        raise GovernanceError('Yerel-only modu seçili. Katalog akışı için Informatica bağlantısını tamamla.')
    settings = json.loads((directory / 'settings.json').read_text())
    secret = Path(os.environ.get('INFA_SECRET_DIR', '/infa'))
    def read(name):
        return (secret / name).read_text().strip()
    return catalog(settings, Client(read('api-host'), read('org-id'), read('api-token')))

def execute_selected(asset_id, selected_metric, loader, cube_request):
    records = loader()
    entry = next((r for r in records if r['assetId'] == asset_id and r['metricId'] == selected_metric), None)
    if not entry or not entry['queryable']:
        raise GovernanceError('Seçilen katalog kaydı güncel olarak doğrulanamadı; Cube çağrılmadı.')
    query = {'measures': [entry['metricId']], 'dimensions': ['Sales.month', 'Sales.channel'], 'filters': [{'member': 'Sales.channel', 'operator': 'equals', 'values': ['HoReCa']}], 'order': {'Sales.month': 'asc'}}
    response = cube_request('load', query)
    return {'catalog': entry, 'query': query, 'data': response['data'], 'policy': 'application_published_owner_source_binding', 'humanApprovalVerified': False}
