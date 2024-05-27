unit Custom.Entity.Core.Enum;

interface

uses System.Generics.Collections;

type
  TEntityCoreEnum<T> = class
  protected
    class function ArrayToArrayString: TArray<String>; virtual; abstract;
    class function CastArrayToString(const AEnumArray: Variant): TArray<String>;
  public
    class function ToString(const AEnum: T): String; reintroduce;
    class function ToInteger(const AEnum: T): Integer;
    class function Name(const AEnum: T): String;
    class function ToArray(const AString: String): TArray<T>;
  end;

  {$SCOPEDENUMS ON}
  TEntityCoreModelStatus = (Browser = 0, Inserted = 1, Updated = 2, Deleted = 3);
  TEntityCoreModelStatusEnum = TEntityCoreEnum<TEntityCoreModelStatus>;

  TEntityCoreConnectionDriver = (FB, MSSQL, Ora, PG, SQLite);
  TEntityCoreConnectionDriverEnum = class(TEntityCoreEnum<TEntityCoreConnectionDriver>)
  private
    const FEntityCoreConnectionDrive: array[TEntityCoreConnectionDriver] of string = ('Firebird', 'SQL Server', 'Oracle', 'Postgres', 'SQLite');
  protected
    class function ArrayToArrayString: TArray<String>; override;
  end;
  {$SCOPEDENUMS OFF}

implementation

uses
  System.Rtti, System.SysUtils, System.TypInfo, System.Variants;

{ TEntityCoreEnum<T> }

class function TEntityCoreEnum<T>.CastArrayToString(const AEnumArray: Variant): TArray<String>;
begin

end;

class function TEntityCoreEnum<T>.Name(const AEnum: T): String;
begin
  var LIndex := GetEnumValue(TypeInfo(T), TRttiEnumerationType.GetName<T>(AEnum));
  Result := ArrayToArrayString[LIndex];
end;

class function TEntityCoreEnum<T>.ToArray(const AString: String): TArray<T>;
begin
  Result := nil;

  var LEnumList := AString.Split([',']);

  for var LEnum in LEnumList do
  begin
    Insert(TRttiEnumerationType.GetValue<T>(LEnum), Result, Length(Result));
  end;
end;

class function TEntityCoreEnum<T>.ToInteger(const AEnum: T): Integer;
begin
  Result := GetEnumValue(TypeInfo(T),
                         TRttiEnumerationType.GetName<T>(AEnum));
end;

class function TEntityCoreEnum<T>.ToString(const AEnum: T): String;
begin
  Result := ToInteger(AEnum).ToString;
end;

{ TEntityCoreConnectionDriverEnum }

class function TEntityCoreConnectionDriverEnum.ArrayToArrayString: TArray<String>;
begin
//  Result := CastArrayToString(FEntityCoreConnectionDrive);
end;

end.
