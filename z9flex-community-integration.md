# Z9/Flex Community API Integration Plan

This document maps the Z9/Flex Community Profile API to the real-bs Rails data model and proposes a phased implementation plan.

## Reference

- **OpenAPI spec**: `~/git/z9flex-community/z9flex-swagger-community.yaml` (4742 lines, OpenAPI 3.0)
- **C# client**: `~/git/z9flex-community/z9flex-client-csharp/`
- **License**: Apache 2.0

## Z9/Flex Community API Overview

86 endpoints across these domains:

| Domain | Entities | Endpoints | Notes |
|--------|----------|-----------|-------|
| Dev (Devices) | Dev (base), NodeDev, Controller, Door, CredReader, Sensor, Actuator | 28 | Type hierarchy via `devType` discriminator |
| Credentials | Cred, CredTemplate | 8 | Card/PIN, biometric, username/password |
| Card Formats | DataFormat/BinaryFormat, DataLayout/BasicDataLayout | 8 | Bit-level Wiegand/Prox encoding |
| Privileges | DoorAccessPriv | 4 | Door access with schedule restrictions |
| Schedules | Sched | 4 | Time intervals with day/holiday rules |
| Holidays | Hol, HolCal, HolType | 12 | Holiday calendars for schedule overrides |
| Events | Evt | 2 | Read-only event log |
| Encryption | EncryptionKey | 4 | DB-based keystore |
| Device Actions | DoorModeChange, DoorMomentaryUnlock | 2 | Command endpoints |
| Auth | Authenticate | 1 | Session token auth |
| Misc | CredHolder Import, Terminate | 2 | Bulk import, server control |

### API Patterns

- **CRUD convention**: `/{entity}/save` (POST create), `/{entity}/list` (GET), `/{entity}/update/{id}` (POST), `/{entity}/delete/{id}` (POST)
- **List responses**: All return `*ListResponse` with `offset`, `max`, `count`, `instanceList`
- **Object references**: `ObjRef` with `type`, `name`, `unid`, `tag`, `uuid`, `externalId`
- **Identity**: Every entity has `unid` (integer), `uuid` (string), `tag` (integer version), `version` (integer)
- **Polymorphism**: Dev, Priv, DataFormat, DataLayout, BinaryElement all use discriminator-based subtyping

### Device Hierarchy

All hardware is a "Dev" with `devType` discriminator:

| devType | Subclass | Description |
|---------|----------|-------------|
| 0 | NodeDev | Z9/Flex server node |
| 1 | Controller | Access control panel (IO controller) |
| 2 | Sensor | Input (door contact, REX, tamper, power, battery) |
| 3 | Actuator | Output (door strike, LED, beeper, relay) |
| 4 | CredReader | Card/credential reader (OSDP) |
| 5 | Door | Access-controlled portal |

Devices form a tree via `physicalParent`/`logicalParent` references, with `physicalChildren`/`logicalChildren` arrays.

### Credential Model

```
Cred
  +-- CredTemplate (type definition: card/PIN, biometric, etc.)
  |     +-- CardPinTemplate (defines what's required/optional)
  |           +-- DataLayout -> DataFormat -> BinaryElement[]
  +-- CardPin (actual card number, facility code, PIN)
  +-- privBindings[] -> CredPrivBinding
        +-- Priv (DoorAccessPriv)
              +-- DoorAccessPrivElement[]
                    +-- Door (ObjRef)
                    +-- SchedRestriction -> Sched
```

### Schedule/Holiday Model

```
Sched
  +-- SchedElement[] (time intervals)
        +-- SchedDay[] (MON-SUN)
        +-- HolType[] (holiday type refs)
        +-- start/stop (time of day)

HolCal (holiday calendar)
  +-- Hol[] (individual holidays)
        +-- HolType[] (categorization)
        +-- date, numDays, repeat rules
```

## Real-BS Data Model (Current State)

17 tables, 18 models. First pass -- many are stubs with no associations or validations.

### What Exists

| real-bs Model | Columns | Associations |
|---------------|---------|--------------|
| Building | name, address, city, region, country, postal_code | *(none defined)* |
| Sector | name, building_id, parent_id | belongs_to :building, :parent |
| AccessController | name, model, brand, is_virtual, metadata, public_metadata, sector_id | belongs_to :sector |
| EntryWay | name, sector_id, access_controller_id | belongs_to :sector, :access_controller |
| Reader | name, brand, model, serial_number, access_controller_id, entry_way_id, last_known_state, last_state_update | belongs_to :access_controller, :entry_way |
| Sensor | name, brand, model, serial_number, access_controller_id, entry_way_id, last_known_state, last_state_update | belongs_to :access_controller, :entry_way |
| Group | name | *(none)* |
| Person | first_name, last_name, title, phone_number, email, group_id, metadata | belongs_to :group |
| Credential | person_id, credential_type_id | belongs_to :person, :credential_type |
| CredentialType | kind, frequency, protocol | *(none)* |
| CredentialFormat | name, length | *(none)* |
| CredentialFormatField | name | *(none)* |
| CredentialFormatFieldBit | index, position, credential_format_field_id | belongs_to :credential_format_field |
| CredentialFormatParityBit | kind, index | *(none)* |
| CredentialFormatParityBitRange | index, position, credential_format_parity_id | belongs_to :credential_format_parity **(BROKEN -- table doesn't exist)** |
| AccessPath | name | *(none)* |
| AccessRuleSet | name | *(none)* |

### Known Issues

1. **Broken FK**: `credential_format_parity_bit_ranges` references `credential_format_parities` which has no migration
2. **Missing `has_many`**: Only `belongs_to` defined; no inverse associations
3. **No validations, scopes, or methods** on any model
4. **No controllers, routes, views, or API endpoints**

## Entity Mapping: Z9/Flex API <-> real-bs

| Z9/Flex Entity | real-bs Model | Mapping Notes |
|----------------|---------------|---------------|
| Controller | AccessController | Closest match. Flex has devMod, devPlatform, config; RBS has brand, model, is_virtual |
| Door | EntryWay | Flex Door is a device subtype; RBS EntryWay is a physical space |
| CredReader | Reader | Similar. Flex has OSDP config; RBS has brand/model/serial |
| Sensor | Sensor | Similar. Flex has sensorConfig; RBS has brand/model/serial |
| Actuator | *(missing)* | Not modeled in RBS |
| NodeDev | *(missing)* | Not modeled in RBS |
| Dev (base) | *(no base)* | RBS uses separate tables; Flex uses type hierarchy |
| Cred | Credential | RBS is a stub (just FKs); Flex has card data, effective/expires, privBindings |
| CredTemplate | CredentialType | RBS has kind/frequency/protocol; Flex has cardPinTemplate, priority |
| BinaryFormat | CredentialFormat | Partial overlap. Flex has minBits/maxBits/elements; RBS has name/length |
| BinaryElement | CredentialFormatFieldBit | Flex has 3 subtypes (static, parity, field); RBS splits into separate tables |
| DataLayout | *(missing)* | Not modeled in RBS |
| DoorAccessPriv | AccessRuleSet | RBS is name-only stub |
| Sched | *(missing)* | Not modeled |
| Hol/HolCal/HolType | *(missing)* | Not modeled |
| Evt | *(missing)* | Not modeled |
| EncryptionKey | *(missing)* | Not modeled |
| *(none)* | Building | RBS-only: physical location hierarchy |
| *(none)* | Sector | RBS-only: zone within building |
| *(none)* | Group | RBS-only: person grouping |
| *(none)* | Person | RBS-only: Flex uses CredHolder (not in community spec) |
| *(none)* | AccessPath | RBS-only: purpose unclear |

### Key Differences

1. **Device modeling**: Flex uses a single `Dev` type hierarchy with discriminator. RBS uses separate tables (AccessController, Reader, Sensor, EntryWay). Both are valid -- the translation layer maps between them.

2. **Spatial hierarchy**: RBS has Building > Sector > EntryWay (physical space). Flex has Device parent/child trees (logical/physical). These are complementary, not conflicting.

3. **Missing in RBS**: The entire access control logic layer -- schedules, privileges, holidays, events, door modes, device actions, encryption. These are needed to implement a functional subset of the API.

4. **Missing in Flex Community**: Building/Sector (physical locations), Person/Group (credHolder is in the commercial API only).

## Implementation Strategy

### Guiding Principles

1. **API-first**: Implement the Z9/Flex Community API endpoints. Let the API drive what we build.
2. **Minimal RBS changes**: Don't restructure the existing data model upfront. Build a translation layer that maps Flex API shapes to/from RBS models.
3. **TDD**: Every feature starts with a failing test. Unit tests for models/translation, integration tests for API endpoints.
4. **Baby steps**: One entity at a time, simplest first, building toward more complex.
5. **Identify gaps as we go**: Document what RBS model changes are needed only when we hit a wall the translation layer can't solve.

### Phase 0: Foundation

Get the project runnable, fix known issues, establish test infrastructure.

- [ ] **0.1** Fix broken migration (credential_format_parity_bit_ranges FK)
- [ ] **0.2** Run migrations, verify clean `db:migrate` and `db:test:prepare`
- [ ] **0.3** Add missing `has_many` associations to all models
- [ ] **0.4** Add basic model validations (presence, uniqueness where obvious)
- [ ] **0.5** Set up API test infrastructure:
  - Add `rack-test` or similar for integration tests
  - Create `test/integration/` directory
  - Create a base API test helper with JSON request/response helpers
  - Decide on JSON serialization approach (jbuilder already in Gemfile)
- [ ] **0.6** Add API namespace route: `namespace :api, defaults: { format: :json }`
- [ ] **0.7** Write first passing test: health check endpoint returns 200

### Phase 1: Authentication

Implement the `/authenticate` endpoint. Every other endpoint depends on this.

- [ ] **1.1** Write failing integration test: POST /authenticate returns session token
- [ ] **1.2** Implement simple token-based auth (API key or session token)
- [ ] **1.3** Write failing test: unauthenticated requests return 401
- [ ] **1.4** Add `before_action` auth check to base API controller
- [ ] **1.5** Tests pass

### Phase 2: Controller (Device) -- Simplest CRUD Entity

Controller is the most straightforward mapping (AccessController <-> Controller).

- [ ] **2.1** Write failing unit tests: Controller <-> AccessController translation
- [ ] **2.2** Build translation layer: `FlexTranslator::Controller`
  - Flex `Controller` JSON -> Rails `AccessController` attributes
  - Rails `AccessController` -> Flex `Controller` JSON (with `devType`, `devMod`, ObjRef for parent, etc.)
- [ ] **2.3** Write failing integration tests for each endpoint:
  - `GET /controller/list` -> list AccessControllers as Flex Controller JSON
  - `POST /controller/save` -> create AccessController from Flex Controller JSON
  - `POST /controller/update/{id}` -> update AccessController
  - `POST /controller/delete/{id}` -> delete AccessController
- [ ] **2.4** Implement controller + routes
- [ ] **2.5** Document gaps: what Flex Controller fields have no RBS column?
- [ ] **2.6** Tests pass

### Phase 3: Door, CredReader, Sensor

Same pattern as Phase 2, one at a time.

- [ ] **3.1** Door (EntryWay): translation + CRUD + tests
- [ ] **3.2** CredReader (Reader): translation + CRUD + tests
- [ ] **3.3** Sensor (Sensor): translation + CRUD + tests
- [ ] **3.4** Document all gaps found

### Phase 4: Credentials

- [ ] **4.1** Cred (Credential): translation + CRUD + tests
- [ ] **4.2** CredTemplate (CredentialType): translation + CRUD + tests
- [ ] **4.3** Document gaps (CardPin data, effective/expires, privBindings)

### Phase 5: Data Formats

- [ ] **5.1** DataFormat/BinaryFormat (CredentialFormat): translation + CRUD + tests
- [ ] **5.2** DataLayout/BasicDataLayout: assess whether new model needed or can stub
- [ ] **5.3** Document gaps

### Phase 6: Access Rules (Privileges)

- [ ] **6.1** DoorAccessPriv (AccessRuleSet): translation + CRUD + tests
- [ ] **6.2** Assess whether new models are needed for DoorAccessPrivElement, CredPrivBinding

### Phase 7: Schedules & Holidays

- [ ] **7.1** Assess: new models definitely needed (Sched, SchedElement, Hol, HolCal, HolType)
- [ ] **7.2** Propose minimal schema additions
- [ ] **7.3** Implement with TDD

### Phase 8: Events

- [ ] **8.1** Assess: new model needed (Evt)
- [ ] **8.2** Read-only endpoints: `GET /evt/list`, `GET /evt/show/{id}`

### Phase 9: Device Actions & Remaining

- [ ] **9.1** DoorModeChange, DoorMomentaryUnlock (command endpoints)
- [ ] **9.2** EncryptionKey CRUD
- [ ] **9.3** CredHolder import
- [ ] **9.4** Actuator and NodeDev (if needed)

### Phase 10: Gap Assessment & Model Changes

After all phases, compile the full gap list and propose minimal RBS schema changes.

- [ ] **10.1** Consolidated gap report: every Flex field with no RBS column
- [ ] **10.2** Categorize: must-have vs. nice-to-have vs. can-ignore
- [ ] **10.3** Propose migrations
- [ ] **10.4** Implement with TDD

## Gap Tracking

As we implement each phase, we'll record gaps here.

| Phase | Flex Field | RBS Model | Gap Description | Severity |
|-------|-----------|-----------|-----------------|----------|
| *(to be filled during implementation)* | | | | |

## Test Strategy

### Unit Tests (`test/models/`, `test/translators/`)

- Model validations and associations
- Translation layer: Flex JSON <-> RBS model attributes
- Edge cases: missing fields, null values, type coercion

### Integration Tests (`test/integration/`)

- Full HTTP request/response cycle for each API endpoint
- Authentication and authorization
- Pagination (offset/max/count)
- Error responses (404, 422, 401)
- List filtering (devMod, devUse restrictions)

### Fixtures / Factories

- Use Rails fixtures (already scaffolded) or add `factory_bot` if fixtures become unwieldy

## Open Questions

1. Should the API routes mirror Flex exactly (`/controller/list`) or use Rails conventions (`/api/controllers`) with Flex-compatible JSON? **Recommendation**: Mirror Flex routes exactly for compatibility.
2. Do we need to support `tag` (optimistic locking version) from day one? **Recommendation**: Stub it initially, implement later.
3. How do we handle `unid` (integer) vs `uuid` (string) identity? RBS uses Rails integer IDs. **Recommendation**: Map `unid` to Rails `id`, generate `uuid` as a secondary identifier.
4. Do we need ObjRef expansion in list responses from the start? **Recommendation**: Start with basic ObjRef (unid + name), add full expansion later.
