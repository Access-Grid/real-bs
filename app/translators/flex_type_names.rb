module FlexTypeNames
  MAP = {
    "IoController" => "Controller",
    "Schedule" => "Sched",
    "CredentialType" => "CredTemplate",
    "HolidayType" => "HolType",
    "HolidayCalendar" => "HolCal",
    "CredentialFormat" => "DataFormat",
    "AccessRuleSet" => "DoorAccessPriv",
    "Credential" => "Cred"
  }.freeze

  def self.for(record)
    MAP[record.class.name] || record.class.name
  end
end
