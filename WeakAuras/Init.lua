--- @type string, Private
local AddonName, Private = ...
WeakAuras = {}
WeakAuras.L = {}
Private.frames = {}

--- @alias uid string
--- @alias auraId string

--- @class state
--- @field id auraId
--- @field cloneId string?

--- @class Private
--- @field ActivateAuraEnvironment fun(id: auraId?, cloneId: string?, state: state?, states: state[]?, onlyConfig: boolean?)
--- @field ActivateAuraEnvironmentForRegion fun(region: table, onlyConfig: boolean?)
--- @field AuraWarnings AuraWarnings
--- @field AuraEnvironmentWrappedSystem AuraEnvironmentWrappedSystem
--- @field callbacks callbacks
--- @field DebugLog debugLog
--- @field clones table<auraId, table<string, table>>
--- @field ExecEnv table
--- @field LibSpecWrapper LibSpecWrapper
--- @field regions table<auraId, table>
--- @field UIDtoID fun(uid: uid): auraId

--- @alias triggerTypes
--- | "aura"
--- | "aura2"
--- | "custom"

--- @class triggerData
--- @field buffShowOn string
--- @field event string|nil
--- @field itemTypeName table|nil
--- @field instance_size table|nil
--- @field type triggerTypes
--- @field use_showOn boolean|nil
--- @field use_alwaystrue boolean|nil


--- @class triggerUntriggerData
--- @field trigger triggerData
--- @field untrigger triggerData

--- @class conditionCheck
--- @field variable string
--- @field trigger number
--- @field checks conditionCheck[]|nil

--- @class conditionChanges
--- @field property string

--- @class conditionData
--- @field check conditionCheck
--- @field changes conditionChanges

--- @class subRegionData

--- @class actionData
--- @field do_glow boolean
--- @field do_message boolean
--- @field message string
--- @field message_type string


--- @class actions
--- @field start actionData
--- @field finish actionData

--- @class load
--- @field use_realm boolean
--- @field itemtypeequipped table
--- @field size table

--- @alias regionTypes
--- | "aurabar"
--- | "dynamicgroup"
--- | "fallback"
--- | "group"
--- | "icon"
--- | "model"
--- | "progresstexture"
--- | "stopmotion"
--- | "text"
--- | "texture"

--- @class information
--- @field forceEvents boolean|nil
--- @field ignoreOptionsEventErrors boolean|nil
--- @field groupOffset boolean|nil


--- @class auraData
--- @field arcLength number
--- @field actions actions
--- @field conditions conditionData[]|nil
--- @field controlledChildren auraId[]|nil
--- @field displayText string|nil
--- @field grow string|nil
--- @field id auraId
--- @field internalVersion number
--- @field information information
--- @field load load
--- @field orientation string|nil
--- @field parent auraId|nil
--- @field regionType regionTypes
--- @field subRegions subRegionData|nil
--- @field triggers triggerUntriggerData[]
--- @field url string|nil

WeakAuras.normalWidth = 1.3
WeakAuras.halfWidth = WeakAuras.normalWidth / 2
WeakAuras.doubleWidth = WeakAuras.normalWidth * 2

local versionStringFromToc = GetAddOnMetadata("WeakAuras", "Version")
local versionString = "@project-version@"
local buildTime = "@build-time@"

local flavorFromToc = GetAddOnMetadata("WeakAuras", "X-Flavor")
local flavorFromTocToNumber = {
  Vanilla = 1,
  TBC = 2,
  Wrath = 3,
  Mainline = 10
}
local flavor = flavorFromTocToNumber[flavorFromToc]

--@debug@
if versionStringFromToc == "@project-version@" then
  versionStringFromToc = "Dev"
  buildTime = "Dev"
end
--@end-debug@

WeakAuras.versionString = versionStringFromToc
WeakAuras.buildTime = buildTime
WeakAuras.newFeatureString = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:0|t"
WeakAuras.BuildInfo = select(4, GetBuildInfo())

function WeakAuras.IsClassic()
  return flavor == 1
end

function WeakAuras.IsBCC()
  return flavor == 2
end

function WeakAuras.IsWrathClassic()
  return flavor == 3
end

function WeakAuras.IsRetail()
  return flavor == 10
end

function WeakAuras.IsClassicOrBCC()
  return WeakAuras.IsClassic() or WeakAuras.IsBCC()
end

function WeakAuras.IsClassicOrBCCOrWrath()
  return WeakAuras.IsClassic() or WeakAuras.IsBCC() or WeakAuras.IsWrathClassic()
end

function WeakAuras.IsBCCOrWrath()
  return WeakAuras.IsBCC() or WeakAuras.IsWrathClassic()
end

function WeakAuras.IsBCCOrWrathOrRetail()
  return WeakAuras.IsBCC() or WeakAuras.IsWrathClassic() or WeakAuras.IsRetail()
end

function WeakAuras.IsWrathOrRetail()
  return WeakAuras.IsRetail() or WeakAuras.IsWrathClassic()
end


WeakAuras.prettyPrint = function(...)
  print("|cff9900ffWeakAuras:|r ", ...)
end

-- Force enable WeakAurasCompanion and Archive because some addon managers interfere with it
EnableAddOn("WeakAurasCompanion")
EnableAddOn("WeakAurasArchive")

local libsAreOk = true
do
  local StandAloneLibs = {
    "Archivist",
    "LibStub"
  }
  local LibStubLibs = {
    "CallbackHandler-1.0",
    "AceConfig-3.0",
    "AceConsole-3.0",
    "AceGUI-3.0",
    "AceEvent-3.0",
    "AceGUISharedMediaWidgets-1.0",
    "AceTimer-3.0",
    "AceSerializer-3.0",
    "AceComm-3.0",
    "LibSharedMedia-3.0",
    "LibDataBroker-1.1",
    "LibCompress",
    "SpellRange-1.0",
    "LibCustomGlow-1.0",
    "LibDBIcon-1.0",
    "LibGetFrame-1.0",
    "LibSerialize",
  }
  if WeakAuras.IsClassic() then
    tinsert(LibStubLibs, "LibClassicSpellActionCount-1.0")
    tinsert(LibStubLibs, "LibClassicCasterino")
    tinsert(LibStubLibs, "LibClassicDurations")
  end
  if WeakAuras.IsRetail() then
    tinsert(LibStubLibs, "LibSpecialization")
  end
  for _, lib in ipairs(StandAloneLibs) do
    if not lib then
        libsAreOk = false
        WeakAuras.prettyPrint("Missing library:", lib)
    end
  end
  if LibStub then
    for _, lib in ipairs(LibStubLibs) do
        if not LibStub:GetLibrary(lib, true) then
          libsAreOk = false
          WeakAuras.prettyPrint("Missing library:", lib)
        end
    end
  else
    libsAreOk = false
  end
end

function WeakAuras.IsLibsOK()
  return libsAreOk
end

if not WeakAuras.IsLibsOK() then
  C_Timer.After(1, function() WeakAuras.prettyPrint("WeakAuras is missing necessary libraries. Please reinstall a proper package.") end)
end

-- These function stubs are defined here to reduce the number of errors that occur if WeakAuras.lua fails to compile
function WeakAuras.RegisterRegionType()
end

function WeakAuras.RegisterRegionOptions()
end

function Private.StartProfileSystem()
end

function Private.StartProfileAura()
end

function Private.StopProfileSystem()
end

function Private.StopProfileAura()
end

function Private.StartProfileUID()
end

function Private.StopProfileUID()
end

Private.ExecEnv = {}

-- If WeakAuras shuts down due to being installed on the wrong target, keep the bindings from erroring
function WeakAuras.StartProfile()
end

function WeakAuras.StopProfile()
end

function WeakAuras.PrintProfile()
end

function WeakAuras.CountWagoUpdates()
  -- XXX this is to work around the Companion app trying to use our stuff!
  return 0
end
