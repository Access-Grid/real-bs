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

### Implemented Endpoints (73 of 73 swagger endpoints)

| Group | Endpoints |
|-------|-----------|
| Auth | `POST /authenticate`, `GET /terminate` |
| Health | `GET /api/health` |
| Dev (generic) | `GET /dev/list`, `POST /dev/save`, `POST /dev/update/{id}`, `POST /dev/delete/{id}` |
| Controller | `GET /controller/list`, `POST /controller/save`, `POST /controller/update/{id}`, `POST /controller/delete/{id}` |
| Door | `GET /door/list`, `POST /door/save`, `POST /door/update/{id}`, `POST /door/delete/{id}` |
| CredReader | `GET /credReader/list`, `POST /credReader/save`, `POST /credReader/update/{id}`, `POST /credReader/delete/{id}` |
| Sensor | `GET /sensor/list`, `POST /sensor/save`, `POST /sensor/update/{id}`, `POST /sensor/delete/{id}` |
| Actuator | `GET /actuator/list`, `POST /actuator/save`, `POST /actuator/update/{id}`, `POST /actuator/delete/{id}` |
| NodeDev | `GET /nodeDev/list`, `POST /nodeDev/save`, `POST /nodeDev/update/{id}`, `POST /nodeDev/delete/{id}` |
| Cred | `GET /cred/list`, `POST /cred/save`, `POST /cred/update/{id}`, `POST /cred/delete/{id}` |
| CredTemplate | `GET /credTemplate/list`, `POST /credTemplate/save`, `POST /credTemplate/update/{id}`, `POST /credTemplate/delete/{id}` |
| DataFormat | `GET /dataFormat/list`, `POST /dataFormat/save`, `POST /dataFormat/update/{id}`, `POST /dataFormat/delete/{id}` |
| BinaryFormat | `GET /binaryFormat/list`, `POST /binaryFormat/save`, `POST /binaryFormat/update/{id}`, `POST /binaryFormat/delete/{id}` |
| DataLayout | `GET /dataLayout/list`, `POST /dataLayout/save`, `POST /dataLayout/update/{id}`, `POST /dataLayout/delete/{id}` |
| BasicDataLayout | `GET /basicDataLayout/list`, `POST /basicDataLayout/save`, `POST /basicDataLayout/update/{id}`, `POST /basicDataLayout/delete/{id}` |
| DoorAccessPriv | `GET /doorAccessPriv/list`, `POST /doorAccessPriv/save`, `POST /doorAccessPriv/update/{id}`, `POST /doorAccessPriv/delete/{id}` |
| Sched | `GET /sched/list`, `POST /sched/save`, `POST /sched/update/{id}`, `POST /sched/delete/{id}` |
| HolType | `GET /holType/list`, `POST /holType/save`, `POST /holType/update/{id}`, `POST /holType/delete/{id}` |
| HolCal | `GET /holCal/list`, `POST /holCal/save`, `POST /holCal/update/{id}`, `POST /holCal/delete/{id}` |
| Hol | `GET /hol/list`, `POST /hol/save`, `POST /hol/update/{id}`, `POST /hol/delete/{id}` |
| Evt | `GET /evt/list`, `GET /evt/show/{id}` |
| EncryptionKey | `GET /encryptionKey/list`, `POST /encryptionKey/save`, `POST /encryptionKey/update/{id}`, `POST /encryptionKey/delete/{id}` |
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

### Endpoints

- [ ] `POST /credHolder/import` -- CSV file upload for bulk credential holder import

### Field-Level Gaps

#### DevConfig Subtypes
- [x] **ControllerConfig**: username, password, devInitiatesConnection, encryptionKeyRef, encryptionKeyRefNext, disableEncryption
- [x] **CredReaderConfig**: (ControllerConfig fields) + commType, tamperType, ledType, serialPortAddress
- [x] **SensorConfig**: (ControllerConfig fields) + invert
- [x] **ActuatorConfig**: (ControllerConfig fields) + invert
- [x] **NodeDevConfig**: same fields as ControllerConfig

#### Cred
- [x] `privBindings` -- CredPrivBinding join model with priv, schedRestriction, devAsDoorAccessPriv
- [x] `doorAccessModifiers` -- JSON column on credentials, stored/served/proto-serialized

#### DoorAccessPriv
- [ ] Element `unid` -- not emitted in element_to_flex output
- [ ] `externalId` -- missing on AccessRuleSet model/translator

#### SchedElement
- [ ] Element `unid` -- not emitted in element_to_flex output

#### Extra Fields (in our implementation but NOT in swagger -- evaluate/remove)
- [ ] `Cred.credHolder` -- ObjRef to Person; not in community swagger
- [ ] `CredTemplate.kind`, `CredTemplate.frequency`, `CredTemplate.protocol` -- not in community swagger

### Upstream Schema Gaps (blocked on community spec)
- [ ] `DoorConfig` -- schema referenced in swagger but definition is missing. Door translator stubs `doorConfig: {}`. Implement when upstream adds the schema.
- [ ] `Hol` (individual holidays) missing from DbChange proto -- HolCal and HolType are sent but individual Hol entries with dates are not part of the current proto DbChange message. This means Aporta does not receive actual holiday dates, only holiday types and calendar names. Likely a proto spec gap that needs to be addressed upstream.

### Cross-Cutting
- [ ] `version` / `tag` fields -- optimistic locking, stubbed across all entities
- [ ] ObjRef `type` field uses Rails model names (e.g., "Schedule") not Flex names ("Sched") -- may need alignment
