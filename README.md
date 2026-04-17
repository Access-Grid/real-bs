# real-bs — Z9/Flex Community Profile Server

A Rails 8.0 implementation of the Z9/Flex Community Profile API.

## Setup

```bash
bundle install
bin/rails db:migrate
```

## Running Tests

```bash
# Unit + integration tests (no external deps)
bundle exec rails test

# E2E tests (requires Aporta + osdp-net-pd-sim)
bundle exec rake e2e:test
bundle exec rake e2e:test_access_granted
bundle exec rake e2e:test_access_denied
```

## Architecture

- **Rails 8.0** with SQLite3
- **STI** for device types (`Device` base class with `IoController`, `Door`, `CredReader`, `Sensor`, `Actuator`, `NodeDev`)
- **Translator pattern**: each Flex API entity has a translator class with `to_flex(record)` / `from_flex(json)` class methods
- **BaseController** provides `authenticate!` (sessionToken header), `find_by_id_or_uuid`, and `paginate`
- Routes mirror the Flex API paths exactly (camelCase: `/doorAccessPriv/list`, `/holType/save`, etc.)

## API Reference

The swagger spec is at `~/git/z9flex-community/z9flex-swagger-community.yaml`.

### Implemented Endpoints (102 of 102 swagger endpoints)

| Group | Endpoints |
|-------|-----------|
| Auth | `POST /authenticate`, `GET /terminate` |
| Health | `GET /api/health` |
| Dev (generic) | `GET /dev/list`, `GET /dev/show/{id}`, `POST /dev/save`, `POST /dev/update/{id}`, `POST /dev/delete/{id}` |
| Controller | `GET /controller/list`, `GET /controller/show/{id}`, `POST /controller/save`, `POST /controller/update/{id}`, `POST /controller/delete/{id}` |
| Door | `GET /door/list`, `GET /door/show/{id}`, `POST /door/save`, `POST /door/update/{id}`, `POST /door/delete/{id}` |
| CredReader | `GET /credReader/list`, `GET /credReader/show/{id}`, `POST /credReader/save`, `POST /credReader/update/{id}`, `POST /credReader/delete/{id}` |
| Sensor | `GET /sensor/list`, `GET /sensor/show/{id}`, `POST /sensor/save`, `POST /sensor/update/{id}`, `POST /sensor/delete/{id}` |
| Actuator | `GET /actuator/list`, `GET /actuator/show/{id}`, `POST /actuator/save`, `POST /actuator/update/{id}`, `POST /actuator/delete/{id}` |
| NodeDev | `GET /nodeDev/list`, `GET /nodeDev/show/{id}`, `POST /nodeDev/save`, `POST /nodeDev/update/{id}`, `POST /nodeDev/delete/{id}` |
| Cred | `GET /cred/list`, `GET /cred/show/{id}`, `POST /cred/save`, `POST /cred/update/{id}`, `POST /cred/delete/{id}` |
| CredTemplate | `GET /credTemplate/list`, `GET /credTemplate/show/{id}`, `POST /credTemplate/save`, `POST /credTemplate/update/{id}`, `POST /credTemplate/delete/{id}` |
| DataFormat | `GET /dataFormat/list`, `GET /dataFormat/show/{id}`, `POST /dataFormat/save`, `POST /dataFormat/update/{id}`, `POST /dataFormat/delete/{id}` |
| BinaryFormat | `GET /binaryFormat/list`, `GET /binaryFormat/show/{id}`, `POST /binaryFormat/save`, `POST /binaryFormat/update/{id}`, `POST /binaryFormat/delete/{id}` |
| DataLayout | `GET /dataLayout/list`, `GET /dataLayout/show/{id}`, `POST /dataLayout/save`, `POST /dataLayout/update/{id}`, `POST /dataLayout/delete/{id}` |
| BasicDataLayout | `GET /basicDataLayout/list`, `GET /basicDataLayout/show/{id}`, `POST /basicDataLayout/save`, `POST /basicDataLayout/update/{id}`, `POST /basicDataLayout/delete/{id}` |
| DoorAccessPriv | `GET /doorAccessPriv/list`, `GET /doorAccessPriv/show/{id}`, `POST /doorAccessPriv/save`, `POST /doorAccessPriv/update/{id}`, `POST /doorAccessPriv/delete/{id}` |
| Sched | `GET /sched/list`, `GET /sched/show/{id}`, `POST /sched/save`, `POST /sched/update/{id}`, `POST /sched/delete/{id}` |
| HolType | `GET /holType/list`, `GET /holType/show/{id}`, `POST /holType/save`, `POST /holType/update/{id}`, `POST /holType/delete/{id}` |
| HolCal | `GET /holCal/list`, `GET /holCal/show/{id}`, `POST /holCal/save`, `POST /holCal/update/{id}`, `POST /holCal/delete/{id}` |
| Hol | `GET /hol/list`, `GET /hol/show/{id}`, `POST /hol/save`, `POST /hol/update/{id}`, `POST /hol/delete/{id}` |
| Evt | `GET /evt/list`, `GET /evt/show/{id}` |
| EncryptionKey | `GET /encryptionKey/list`, `GET /encryptionKey/show/{id}`, `POST /encryptionKey/save`, `POST /encryptionKey/update/{id}`, `POST /encryptionKey/delete/{id}` |
| DevStateRecord | `GET /devStateRecord/list` |
| DevActions | `GET /json/doorModeChange`, `GET /json/doorMomentaryUnlock` |

## E2E Test Architecture

Full-stack E2E tests exercise the complete access control pipeline:

```
 real-bs (this app)       Aporta              OSDP PD Sim
 +-----------+     protobuf/TCP      +----------+    OSDP/TCP    +----------+
 | SpCore    | <------ 9723 -------> | .NET     | <--- 9843 ---> | osdp-net |
 | Server    |                       | controller|               | -pd-sim  |
 +-----------+                       +----------+                | port 5230|
                                                                 +----------+
```

**Components:**
- **SpCoreServer** (`lib/spcore_server.rb`) -- Protobuf TCP server speaking Z9 Open Community Protocol
- **DbChangeBuilder** (`lib/db_change_builder.rb`) -- Serializes Rails models to protobuf DbChange messages
- **Aporta** (`~/git/Aporta`) -- Open-source .NET controller, makes local access decisions
- **osdp-net-pd-sim** (`~/git/osdp-net-pd-sim`) -- OSDP PD simulator with HTTP control API

**Test flow:**
1. Create all entities via REST API (IoController, Door, CredReader, formats, schedules, credentials with privBindings)
2. Start PD sim (OSDP listener + HTTP API)
3. Start SpCoreServer (protobuf TCP on 9723)
4. Start Aporta (connects to SpCoreServer + PD sim)
5. SpCoreServer auto-syncs: builds full DbChange via DbChangeBuilder and sends to Aporta
6. Trigger card swipe via PD sim HTTP API
7. Aporta makes access decision, sends event back over protobuf
8. SpCoreServer persists event to Event table
9. Verify ACCESS_GRANTED/DENIED event via `GET /evt/list` REST API

**Prerequisites:** .NET 9.0 SDK, Aporta and osdp-net-pd-sim repos cloned at `~/git/`.

## TODOs

### Field-Level Gaps

#### DevConfig Subtypes
- [x] **ControllerConfig**: username, password, devInitiatesConnection, encryptionKeyRef, encryptionKeyRefNext, disableEncryption
- [x] **CredReaderConfig**: (ControllerConfig fields) + commType, tamperType, ledType, serialPortAddress
- [x] **SensorConfig**: (ControllerConfig fields) + invert
- [x] **ActuatorConfig**: (ControllerConfig fields) + invert
- [x] **NodeDevConfig**: same fields as ControllerConfig
- [x] **DoorConfig**: (ControllerConfig fields) + defaultDoorMode, activateStrikeOnRex, strikeTime, extendedStrikeTime, heldTime, extendedHeldTime

#### Cred
- [x] `privBindings` -- CredPrivBinding join model with priv, schedRestriction, devAsDoorAccessPriv
- [x] `doorAccessModifiers` -- JSON column on credentials, stored/served/proto-serialized

#### DoorAccessPriv
- [x] Element `unid` -- emitted in element_to_flex output
- [x] `externalId` -- on AccessRuleSet model/translator

#### SchedElement
- [x] Element `unid` -- emitted in element_to_flex output

#### Extra Fields (removed -- not in community swagger)
- [x] `CredTemplate.kind`, `CredTemplate.frequency`, `CredTemplate.protocol` -- removed

### Consider
- [ ] `Cred.credHolder` -- ObjRef to Person; useful but not currently in community swagger
- [ ] Consider aligning remaining Ruby class names with Flex names (e.g., CredentialFormat->DataFormat as model name)

### Improvements
- [x] **E2E test verification** -- DoorConfig is now properly serialized in DbChangeBuilder; E2E pipeline confirmed working end-to-end
- [ ] **DevStateRecord enrichment** -- Currently returns empty `devAspectStates`. Could populate COMM state (ONLINE/OFFLINE) based on SpCoreServer connection status, persist aspect states from Aporta events
- [ ] **Query filters** -- Swagger shows query parameters like `devModRestriction.devMods` on devStateRecord/list and general filtering/ordering on other list endpoints; currently list endpoints don't support these filters
- [ ] **Consolidate migrations** -- Roll the `external_dev_mod` columns into the single consolidated migration to keep it clean


### Cross-Cutting
- [x] `version` field -- stored and served across all entities and DevConfig subtypes
- [x] `tag` field -- stored and served across all entities
- [x] `commFamily` on Dev -- removed (not in community swagger)
- [x] DevConfig `unid` and `version` -- served on all config subtypes
- [x] `version` optimistic locking -- Rails `lock_version` column, auto-increments on update, 409 Conflict on stale writes
- [x] ObjRef `type` field aligned to Flex names via `FlexTypeNames` module (IoController->Controller, Schedule->Sched, CredentialType->CredTemplate, HolidayType->HolType, HolidayCalendar->HolCal, CredentialFormat->DataFormat, AccessRuleSet->DoorAccessPriv)
- [x] `DoorConfig` -- full implementation with defaultDoorMode, activateStrikeOnRex, strikeTime, extendedStrikeTime, heldTime, extendedHeldTime + base config fields
- [x] `show/{id}` endpoints for all 20 entity types (GET returns `{ instance: <entity> }`)
- [x] `DevStateRecord` -- read-only endpoint, returns device state records for all devices
- [x] `Dev.externalDevModText` / `Dev.externalDevModId` -- stored and served on all device types
