unit Custom.Entity.Core.Connection;

interface

uses
  Data.DB,
  Custom.Entity.Core.Model;

type
  IEntityCoreConnection = interface
    ['{694B3615-98C3-47B8-BA64-6DB045791FDA}']
    function ExecSQL(const ASQL: String; AIgnoreObjNotExists: Boolean = False): LongInt; overload;
    function ExecSQL(const ASQL: String; const AParams: array of Variant): LongInt; overload;
    function ExecSQL(const ASQL: String; const AParams: array of Variant;
      const ATypes: array of TFieldType): LongInt; overload;
    function ExecSQL(const ASQL: String; var AResultSet: TDataSet): LongInt; overload;
    function ExecSQLScalar(const ASQL: String): Variant; overload;
    function ExecSQLScalar(const ASQL: String; const AParams: array of Variant): Variant; overload;
    function ExecSQLScalar(const ASQL: String; const AParams: array of Variant;
      const ATypes: array of TFieldType): Variant; overload;
    function ExecSQL(const ASQL: String; AParams: TParams): LongInt; overload;
    function ExecSQL(const ASQL: String; AParams: TParams; var AResultSet: TDataSet): LongInt; overload;
    function SupportedJson: Boolean;
    function TableExists(const ATableName: String): Boolean;
    function FieldExists(const ATableName, AFieldName: String): Boolean;
    function DatabaseExists(const ADatabaseName: String): Boolean;
    function UniqueKeyExists(const ATableName, AUniquekeyName: String): String;
    function IsFirebird: Boolean;
    function IsSQLite: Boolean;
    function IsSQLServer: Boolean;
    function IsMySQL: Boolean;
    function GetDefaultConfiguration: String;

    procedure Commit;
    procedure Rollback;
    procedure SetConfiguration(const ADatabaseName: String); overload;
    procedure SetConfiguration(const ADriverID, AServer: String); overload;
    procedure SetConfiguration(const ADriverID, AServer, AUserName, APassword: String); overload;
    procedure SetConfiguration(const ADriverID, AServer, AUserName, APassword: String; APort: Integer); overload;
    procedure SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String); overload;
    procedure SetConfiguration(const ADatabaseName, ADriverID, AServer, AUserName, APassword: String; APort: Integer); overload;
    procedure LoadFromFile(const AFileName: String);
    procedure InsertRecord(const AModel: TEntityCoreModel; out AIdKey: Int64);
    procedure UpdateRecord(const AModel: TEntityCoreModel);
    procedure Close;
    procedure Open;
    procedure StartTransaction;
  end;

implementation

end.
