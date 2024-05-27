unit Custom.Entity.Core.Attributes;

interface

uses System.Rtti
{$IFDEF SWAGGER}
    , GBSwagger.Model.Attributes
{$ENDIF};

type
  TEntityCoreAttibute = class(TCustomAttribute)
  private
    FValue: TValue;
  public
    constructor Create(const AValue: String); overload;
    constructor Create(const AValue: TClass); overload;
    property Value: TValue read FValue;
  end;

{$IFDEF SWAGGER}

  StringSize = class(SwagString)
  end;

  NotNull = class(SwagRequired);
  Ignore  = class(SwagIgnore);
  IsEnum  = class(SwagEnum);

  ReadOnly = class(SwagProp)
  public
    constructor Create; overload;
  end;
{$ELSE}
  Ignore   = class(TCustomAttribute);
  NotNull  = class(TCustomAttribute);
  IsEnum   = class(TCustomAttribute);
  ReadOnly = class(TCustomAttribute);

  StringSize = class(TCustomAttribute)
  private
    FMaxLength: Integer;
    FMinLength: Integer;
  public
    constructor Create(const AMaxLength: Integer); overload;
    constructor Create(const AMaxLength, AMinLength: Integer); overload;

    property MaxLength: Integer read FMaxLength;
    property MinLength: Integer read FMinLength;
  end;
{$ENDIF}

  ForeignKey             = class(TEntityCoreAttibute);
  DatabaseName           = class(TEntityCoreAttibute);
  TableName              = class(TEntityCoreAttibute);
  EndpointTag            = class(TEntityCoreAttibute);
  EndpointDescription    = class(TEntityCoreAttibute);
  FormatValue            = class(TEntityCoreAttibute);
  PrimaryKey             = class(TCustomAttribute);
  AutoIncremental        = class(TCustomAttribute);
  IsBoolean              = class(TCustomAttribute);
  Identity               = class(TCustomAttribute);
  NoShowPrimaryKeyPut    = class(TCustomAttribute);
  NoShowPrimaryKeyDelete = class(TCustomAttribute);

implementation

{ TEntityCoreAttibute }

constructor TEntityCoreAttibute.Create(const AValue: String);
begin
  FValue := AValue;
end;

{ StringSize }
{$IF NOT DEFINED(SWAGGER)}
constructor StringSize.Create(const AMaxLength, AMinLength: Integer);
begin
  FMaxLength := AMaxLength;
  FMinLength := AMinLength;
end;

constructor StringSize.Create(const AMaxLength: Integer);
begin
  Create(AMaxLength, 0);
end;
{$ENDIF}

constructor TEntityCoreAttibute.Create(const AValue: TClass);
begin
  FValue := AValue;
end;

{$IFDEF SWAGGER}
{ ReadOnly }
constructor ReadOnly.Create;
begin
  Self.Create(False, True);
end;
{$ENDIF}

end.
