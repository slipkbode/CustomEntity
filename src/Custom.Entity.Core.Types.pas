unit Custom.Entity.Core.Types;

interface

uses Custom.Entity.Core.Constant, System.Variants, System.TypInfo, System.Rtti,
  System.JSON;

type
  Nullable<T> = record
  strict private
    FExpression: String;
    FHasValue  : String;
    FName      : String;
    FValue     : T;
  private
    class function IsEqual(const ALeft, ARight: T): Boolean; static;
    class function MultiplyValue(const ALeft: T; ARight: T): T; static;
    class function GreatThanValue(const ALeft: T; ARight: T): Boolean; static;
    class function GreatThanOrEqualValue(const ALeft: T; ARight: T): Boolean; static;
    class function LessThanValue(const ALeft: T; ARight: T): Boolean; static;
    class function LessThanOrEqualValue(const ALeft: T; ARight: T): Boolean; static;
  public
    class operator Equal(const ALeft, ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator Equal(const ALeft: Nullable<T>; const ARight: T): Nullable<Boolean>; overload;
    class operator Equal(const ALeft: T; const ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator NotEqual(const ALeft, ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator NotEqual(const ALeft: Nullable<T>; const ARight: T): Nullable<Boolean>; overload;
    class operator NotEqual(const ALeft: T; const ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator Implicit(const AValue: T): Nullable<T>; overload;
    class operator Implicit(const AValue: Variant): Nullable<T>; overload;
    class operator Implicit(const AValue: Nullable<T>): T; overload;
    class operator Implicit(const AValue: Nullable<T>): Variant; overload;
    class operator Implicit(const AValue: TValue): Nullable<T>; overload;
    class operator Implicit(const AValue: Pointer): Nullable<T>; overload;
    class operator LogicalAnd(const ALeft, ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator LogicalOr(const ALeft, ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator LogicalNot(const ALeft: Nullable<T>): Nullable<Boolean>; overload;
    class operator Multiply(const ALeft, ARight: Nullable<T>): Nullable<T>; overload;
    class operator Multiply(const ALeft: Nullable<T>; ARight: T): Nullable<T>; overload;
    class operator Multiply(const ALeft: T; ARight: Nullable<T>): Nullable<T>; overload;
    class operator GreaterThan(const ALeft: T; ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator GreaterThan(const ALeft: Nullable<T>; ARight: T): Nullable<Boolean>; overload;
    class operator GreaterThan(const ALeft, ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator GreaterThanOrEqual(const ALeft: T; ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator GreaterThanOrEqual(const ALeft: Nullable<T>; ARight: T): Nullable<Boolean>; overload;
    class operator GreaterThanOrEqual(const ALeft, ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator LessThan(const ALeft: T; ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator LessThan(const ALeft: Nullable<T>; ARight: T): Nullable<Boolean>; overload;
    class operator LessThan(const ALeft, ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator LessThanOrEqual(const ALeft: T; ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator LessThanOrEqual(const ALeft: Nullable<T>; ARight: T): Nullable<Boolean>; overload;
    class operator LessThanOrEqual(const ALeft, ARight: Nullable<T>): Nullable<Boolean>; overload;
    class operator Add(const ALeft: Nullable<T>; ARight: T): Nullable<T>; overload;
    class operator Add(const ALeft: T; ARight: Nullable<T>): Nullable<T>; overload;
    class operator Add(const ALeft: Nullable<T>; ARight: Nullable<T>): Nullable<T>; overload;
    class operator Divide(const ALeft: Nullable<T>; ARight: Nullable<T>): Nullable<T>; overload;
    class operator Divide(const ALeft: Nullable<T>; ARight: T): Nullable<T>; overload;
    class operator Divide(const ALeft: T; ARight: Nullable<T>): Nullable<T>; overload;

    function IsNull: Boolean;
    function &As: String; overload;
    function &As(const AArgs: String): String; overload;
    function ToJSON(AFormatDateTime: String = 'yyyy-mm-dd HH:mm:ss'): TJsonValue;
    function GetDataType: PTypeInfo;
    function GetValue: T;
    function FromJSON(const AJSONValue: TJSONValue): Nullable<T>;

    procedure Clear;
    procedure SetValue(const AValue: T);
    procedure SetName(const Value: String);

    property Expression: String read FExpression write FExpression;
    property Value: T read GetValue write SetValue;
    property Name : String read FName;

    constructor Create(const AValue: T); overload;
    constructor Create(const AValue: Variant); overload;
  end;

  TArrayProperties = TArray<TRttiProperty>;
  TArrayValue      = TArray<TValue>;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  Custom.Entity.Core.Mapper;

{ Nullable<T> }

class operator Nullable<T>.Equal(const ALeft, ARight: Nullable<T>): Nullable<Boolean>;
begin
  inherited;
  Result            := IsEqual(ALeft.Value, ARight.Value);
  Result.Expression := Format(TEntityCoreConstant.cExpressionEqual,
                              [ALeft.Name, ARight.Name]);
end;

class operator Nullable<T>.Add(const ALeft: Nullable<T>; ARight: T): Nullable<T>;
begin
  inherited;
  var LRightValue := TValue
                         .From<T>(ARight)
                         .AsVariant;

  Result.SetValue(TValue
                     .FromVariant(TValue
                                     .From<T>(ALeft.Value)
                                     .AsVariant +
                                  LRightValue)
                     .AsType<T>);

  if TEntityCoreMapper.GetType<T>.TypeKind in [TTypeKind.tkString, TTypeKind.tkLString, TTypeKind.tkWString, TTypeKind.tkUString] then
  begin
    Result.Expression := Format(TEntityCoreConstant.cExpressionAddString, [ALeft.Name, LRightValue]);
  end
  else
  begin
    Result.Expression := Format(TEntityCoreConstant.cExpressionAddNumber, [ALeft.Name, LRightValue]);;
  end;
end;

class operator Nullable<T>.Add(const ALeft: T; ARight: Nullable<T>): Nullable<T>;
begin
  inherited;
  var LLeftValue := TValue
                         .From<T>(ALeft)
                         .AsVariant;

  Result.SetValue(TValue
                     .FromVariant(LLeftValue +
                                  TValue
                                     .From<T>(ARight.Value)
                                     .AsVariant)
                     .AsType<T>);

  if TEntityCoreMapper.GetType<T>.TypeKind in [TTypeKind.tkString, TTypeKind.tkLString, TTypeKind.tkWString, TTypeKind.tkUString] then
  begin
    Result.Expression := Format(TEntityCoreConstant.cExpressionAddString, [LLeftValue, ARight.Name]);
  end
  else
  begin
    Result.Expression := Format(TEntityCoreConstant.cExpressionAddNumber, [LLeftValue, ARight.Name]);
  end;
end;

function Nullable<T>.&As(const AArgs: String): String;
begin
  Result := Format(TEntityCoreConstant.cExpressionAs, [&As, AArgs]);
end;

function Nullable<T>.&As: String;
begin
  Result := FName;
end;

class operator Nullable<T>.Add(const ALeft: Nullable<T>; ARight: Nullable<T>): Nullable<T>;
begin
  Result.SetValue(TValue
                     .FromVariant(TValue
                                     .From<T>(ALeft.Value)
                                     .AsVariant +
                                  TValue
                                     .From<T>(ARight.Value)
                                     .AsVariant)
                     .AsType<T>);

  if TEntityCoreMapper.GetType<T>.TypeKind in [TTypeKind.tkString, TTypeKind.tkLString, TTypeKind.tkWString, TTypeKind.tkUString] then
  begin
    Result.Expression := Format(TEntityCoreConstant.cExpressionAddString, [ALeft.Name, ARight.Name]);
  end
  else
  begin
    Result.Expression := Format(TEntityCoreConstant.cExpressionAddNumber, [ALeft.Name, ARight.Name]);
  end;
end;

procedure Nullable<T>.Clear;
begin
  FValue    := Default(T);
  FHasValue := DefaultFalseBoolStr;
end;

constructor Nullable<T>.Create(const AValue: Variant);
begin
  if not VarIsNull(AValue) and not VarIsEmpty(AValue) then
  begin
    Create(TValue.FromVariant(AValue).AsType<T>)
  end
  else
    Clear;
end;

constructor Nullable<T>.Create(const AValue: T);
begin
  SetValue(AValue);
end;

class operator Nullable<T>.Divide(const ALeft: Nullable<T>;ARight: Nullable<T>): Nullable<T>;
begin
  var LValue := TValue.From<T>(ALeft.Value).AsVariant / TValue.From<T>(ARight.Value).AsVariant;

  Result := TValue.FromVariant(LValue).AsType<T>;
end;

class operator Nullable<T>.Divide(const ALeft: Nullable<T>;ARight: T): Nullable<T>;
begin
  var LValue := TValue.From<T>(ALeft.Value).AsVariant / TValue.From<T>(ARight).AsVariant;

  Result := TValue.FromVariant(LValue).AsType<T>;
end;

class operator Nullable<T>.Divide(const ALeft: T; ARight: Nullable<T>): Nullable<T>;
begin
  var LValue := TValue.From<T>(ALeft).AsVariant / TValue.From<T>(ARight.Value).AsVariant;

  Result := TValue.FromVariant(LValue).AsType<T>;

end;

class operator Nullable<T>.Equal(const ALeft: T; const ARight: Nullable<T>): Nullable<Boolean>;
begin
  inherited;
  Result            := IsEqual(ALeft, ARight.Value);
  Result.Expression := Format(TEntityCoreConstant.cExpressionEqual,
                              [ARight.Name, TValue.From<T>(ARight).AsVariant]);
end;

function Nullable<T>.FromJSON(const AJSONValue: TJSONValue): Nullable<T>;
begin
  if AJSONValue is TJSONNull then
  begin
    Clear;
  end
  else if not (AJSONValue is TJSONObject) and not (AJSONValue is TJSONArray) then
  begin
    Result := Nullable<T>.Create(AJSONValue.GetValue<T>);
  end;
end;

class operator Nullable<T>.NotEqual(const ALeft, ARight: Nullable<T>): Nullable<Boolean>;
begin
  inherited;
  Result            := not IsEqual(ALeft.Value, ARight.Value);
  Result.Expression := Format(TEntityCoreConstant.cExpressionEqual,
                              [ALeft.Name, ARight.Name]);
end;

class operator Nullable<T>.NotEqual(const ALeft: T; const ARight: Nullable<T>): Nullable<Boolean>;
begin
  inherited;
  Result            := not IsEqual(ALeft, ARight.Value);
  Result.Expression := Format(TEntityCoreConstant.cExpressionEqual,
                              [ARight.Name, TValue.From<T>(ARight).AsVariant]);
end;

class operator Nullable<T>.Implicit(const AValue: Nullable<T>): T;
begin
  inherited;
  Result := AValue.Value;
end;

class operator Nullable<T>.Implicit(const AValue: Variant): Nullable<T>;
begin
  Result := Nullable<T>.Create(AValue);
end;

class operator Nullable<T>.Implicit(const AValue: Nullable<T>): Variant;
begin
  Result := Null;

  if not AValue.IsNull then
  begin
    Result := TValue.From<T>(AValue).AsVariant;
  end;
end;

class operator Nullable<T>.Implicit(const AValue: TValue): Nullable<T>;
begin
  Result := Nullable<T>.Create(AValue.AsType<T>);
end;

class operator Nullable<T>.Implicit(const AValue: Pointer): Nullable<T>;
begin
  if AValue = nil then
  begin
    Result.Clear;
  end
  else
  begin
    Result := Nullable<T>.Create(T(AValue^));
  end;
end;

class function Nullable<T>.IsEqual(const ALeft, ARight: T): Boolean;
begin
  Result := TEqualityComparer<T>
                            .Default
                            .Equals(ALeft,
                                    ARight);
end;

function Nullable<T>.IsNull: Boolean;
begin
  Result := FHasValue.IsEmpty or FHasValue.Equals(DefaultFalseBoolStr);
end;

procedure Nullable<T>.SetName(const Value: String);
begin
  FName := Value;
end;

procedure Nullable<T>.SetValue(const AValue: T);
begin
  FValue    := AValue;
  FHasValue := DefaultTrueBoolStr;
end;

function Nullable<T>.ToJSON(AFormatDateTime: String = 'yyyy-mm-dd HH:mm:ss'): TJsonValue;
begin
  if IsNull then
  begin
    Exit(TJSONNull.Create);
  end;

  var LValue := TValue.From<T>(Value);

  case GetDataType.Kind of
    tkInteger:
      begin
        Result := TJSONNumber.Create(LValue.AsInteger);
      end;
    tkString, tkUString:
      begin
        Result := TJSONString.Create(LValue.AsString);
      end;
    tkFloat:
      begin
        if LValue.IsType<TDate> or LValue.IsType<TDateTime> then
        begin
          Result := TJSONString
                          .Create(FormatDateTime(AFormatDateTime,
                                                 LValue.AsType<TDateTime>
                                                 )
                                  );

          if Result.Value.Contains('1899') then
          begin
            Result.Free;
            Result := TJSONNull.Create;
          end;
        end
        else
          Result := TJSONNumber.Create(LValue.AsExtended);
      end;
    tkEnumeration:
      begin
        if LValue.IsType<Boolean> then
        begin
          Result := TJSONBool.Create(LValue.AsBoolean);
        end
        else
          Result := TJSONString.Create(GetEnumName(TypeInfo(T), LValue.AsOrdinal));
        end;
  else
    Result := TJSONNull.Create;
  end;
end;

class operator Nullable<T>.Implicit(const AValue: T): Nullable<T>;
begin
  inherited;
  Result := Nullable<T>.Create(AValue);
end;

class operator Nullable<T>.Equal(const ALeft: Nullable<T>; const ARight: T): Nullable<Boolean>;
begin
  inherited;
  Result := IsEqual(ALeft.Value, ARight);

  Result.Expression := Format(TEntityCoreConstant.cExpressionEqual, [ALeft.Name, TValue.From<T>(ARight).AsVariant]);
end;

class operator Nullable<T>.NotEqual(const ALeft: Nullable<T>; const ARight: T): Nullable<Boolean>;
begin
  inherited;
  Result := not IsEqual(ALeft.Value, ARight);

  Result.Expression := Format(TEntityCoreConstant.cExpressionEqual, [ALeft.Name, TValue.From<T>(ARight).AsVariant]);
end;

class operator Nullable<T>.LogicalAnd(const ALeft, ARight: Nullable<T>): Nullable<Boolean>;
begin
  inherited;
  var LValid := TValue.From<T>(ALeft.Value).AsBoolean and TValue.From<T>(ARight.Value).AsBoolean;

  Result.SetValue(LValid);
  Result.Expression := Format(TEntityCoreConstant.cExpressionAnd,
                              [ALeft.Expression, ARight.Expression]);
end;

class operator Nullable<T>.LogicalNot(const ALeft: Nullable<T>): Nullable<Boolean>;
begin
  inherited;
  Result := not TValue.From<T>(ALeft.Value).AsBoolean;
  Result.Expression := 'not ' + ALeft.Expression;
end;

class operator Nullable<T>.LogicalOr(const ALeft, ARight: Nullable<T>): Nullable<Boolean>;
begin
  inherited;
  var LValid := TValue.From<T>(ALeft.Value).AsBoolean or TValue.From<T>(ARight.Value).AsBoolean;

  Result.SetValue(LValid);
  Result.Expression := Format(TEntityCoreConstant.cExpressionOr,
                              [ALeft.Expression, ARight.Expression]);
end;

class operator Nullable<T>.Multiply(const ALeft: T; ARight: Nullable<T>): Nullable<T>;
begin
  Result.SetValue(MultiplyValue(ALeft, ARight.Value));
end;

class operator Nullable<T>.Multiply(const ALeft: Nullable<T>; ARight: T): Nullable<T>;
begin
  Result.SetValue(MultiplyValue(ALeft.Value, ARight));
end;

class function Nullable<T>.MultiplyValue(const ALeft: T; ARight: T): T;
begin
  Result := TValue.From(0).AsType<T>;

  var LRttiType := TEntityCoreMapper.GetType<T>;

  if LRttiType.TypeKind = TTypeKind.tkInteger then
  begin
    Result := TValue
                 .From<Integer>(TValue
                                   .From<T>(ALeft)
                                   .AsInteger * TValue
                                                   .From<T>(ARight)
                                                   .AsInteger)
                 .AsType<T>;
  end
  else if LRttiType.TypeKind = TTypeKind.tkFloat then
  begin
    Result := TValue
                 .From<Extended80>(TValue
                                   .From<T>(ALeft)
                                   .AsExtended * TValue
                                                   .From<T>(ARight)
                                                   .AsExtended)
                 .AsType<T>;
  end;
end;

class function Nullable<T>.GreatThanValue(const ALeft: T; ARight: T): Boolean;
begin
  case TEntityCoreMapper.GetType<T>.TypeKind of
    TTypeKind.tkInteger:
    begin
      Result := TValue
                   .From<T>(ALeft)
                   .AsInteger > TValue
                                   .From<T>(ARight)
                                   .AsInteger;
    end;
    TTypeKind.tkFloat:
    begin
      Result := TValue
                   .From<T>(ALeft)
                   .AsExtended > TValue
                                   .From<T>(ARight)
                                   .AsExtended;
    end
    else
    begin
      Result := False;
    end;
  end;
end;

class function Nullable<T>.LessThanValue(const ALeft: T; ARight: T): Boolean;
begin
  case TEntityCoreMapper.GetType<T>.TypeKind of
    TTypeKind.tkInteger:
    begin
      Result := TValue
                   .From<T>(ALeft)
                   .AsInteger < TValue
                                   .From<T>(ARight)
                                   .AsInteger;
    end;
    TTypeKind.tkFloat:
    begin
      Result := TValue
                   .From<T>(ALeft)
                   .AsExtended < TValue
                                   .From<T>(ARight)
                                   .AsExtended;
    end
    else
    begin
      Result := False;
    end;
  end;
end;

class function Nullable<T>.GreatThanOrEqualValue(const ALeft: T; ARight: T): Boolean;
begin
  case TEntityCoreMapper.GetType<T>.TypeKind of
    TTypeKind.tkInteger:
    begin
      Result := TValue
                   .From<T>(ALeft)
                   .AsInteger >= TValue
                                   .From<T>(ARight)
                                   .AsInteger;
    end;
    TTypeKind.tkFloat:
    begin
      Result := TValue
                   .From<T>(ALeft)
                   .AsExtended >= TValue
                                   .From<T>(ARight)
                                   .AsExtended;
    end
    else
    begin
      Result := False;
    end;
  end;
end;

class function Nullable<T>.LessThanOrEqualValue(const ALeft: T; ARight: T): Boolean;
begin
  case TEntityCoreMapper.GetType<T>.TypeKind of
    TTypeKind.tkInteger:
    begin
      Result := TValue
                   .From<T>(ALeft)
                   .AsInteger <= TValue
                                   .From<T>(ARight)
                                   .AsInteger;
    end;
    TTypeKind.tkFloat:
    begin
      Result := TValue
                   .From<T>(ALeft)
                   .AsExtended <= TValue
                                   .From<T>(ARight)
                                   .AsExtended;
    end
    else
      Result := False;
  end;
end;

class operator Nullable<T>.Multiply(const ALeft, ARight: Nullable<T>): Nullable<T>;
begin
  inherited;
  Result.SetValue(MultiplyValue(ALeft.Value, ARight.Value));
end;

class operator Nullable<T>.GreaterThan(const ALeft: T; ARight: Nullable<T>): Nullable<Boolean>;
begin
  Result.SetValue(GreatThanValue(ALeft, ARight.Value));
  Result.Expression := Format(TEntityCoreConstant.cExpressionGreatThan,
                              [ARight.Name, TValue.From<T>(ALeft).AsVariant]);
end;

class operator Nullable<T>.GreaterThan(const ALeft: Nullable<T>; ARight: T): Nullable<Boolean>;
begin
  Result.SetValue(GreatThanValue(ALeft.Value, ARight));
  Result.Expression := Format(TEntityCoreConstant.cExpressionGreatThan,
                              [ALeft.Name, TValue.From<T>(ARight).AsVariant]);
end;

function Nullable<T>.GetDataType: PTypeInfo;
begin
  Result := TypeInfo(T);
end;

function Nullable<T>.GetValue: T;
begin
  Result := FValue;
end;

class operator Nullable<T>.GreaterThan(const ALeft, ARight: Nullable<T>): Nullable<Boolean>;
begin
  Result.SetValue(GreatThanValue(ALeft.Value, ARight.Value));
  Result.Expression := Format(TEntityCoreConstant.cExpressionGreatThan,
                              [ALeft.Name, ARight.Name]);
end;

class operator Nullable<T>.GreaterThanOREqual(const ALeft: T; ARight: Nullable<T>): Nullable<Boolean>;
begin
  Result.SetValue(GreatThanOrEqualValue(ALeft, ARight.Value));
  Result.Expression := Format(TEntityCoreConstant.cExpressionGreatThanOrEqual,
                              [ARight.Name, TValue.From<T>(ALeft).AsVariant]);
end;

class operator Nullable<T>.GreaterThanOrEqual(const ALeft: Nullable<T>; ARight: T): Nullable<Boolean>;
begin
  Result.SetValue(GreatThanOrEqualValue(ALeft.Value, ARight));
  Result.Expression := Format(TEntityCoreConstant.cExpressionGreatThanOrEqual,
                              [ALeft.Name, TValue.From<T>(ARight).AsVariant]);
end;

class operator Nullable<T>.GreaterThanOrEqual(const ALeft, ARight: Nullable<T>): Nullable<Boolean>;
begin
  Result.SetValue(GreatThanOrEqualValue(ALeft.Value, ARight.Value));
  Result.Expression := Format(TEntityCoreConstant.cExpressionGreatThanOrEqual,
                              [ALeft.Name, ARight.Name]);
end;

class operator Nullable<T>.LessThan(const ALeft: T; ARight: Nullable<T>): Nullable<Boolean>;
begin
  Result.SetValue(LessThanValue(ALeft, ARight.Value));
  Result.Expression := Format(TEntityCoreConstant.cExpressionLessThan,
                              [ARight.Name, TValue.From<T>(ALeft).AsVariant]);
end;

class operator Nullable<T>.LessThan(const ALeft: Nullable<T>; ARight: T): Nullable<Boolean>;
begin
  Result.SetValue(LessThanValue(ALeft.Value, ARight));
  Result.Expression := Format(TEntityCoreConstant.cExpressionLessThan,
                              [ALeft.Name, TValue.From<T>(ARight).AsVariant]);
end;

class operator Nullable<T>.LessThan(const ALeft, ARight: Nullable<T>): Nullable<Boolean>;
begin
  Result.SetValue(LessThanValue(ALeft.Value, ARight.Value));
  Result.Expression := Format(TEntityCoreConstant.cExpressionLessThan,
                              [ALeft.Name, ARight.Name]);
end;

class operator Nullable<T>.LessThanOrEqual(const ALeft: T; ARight: Nullable<T>): Nullable<Boolean>;
begin
  Result.SetValue(LessThanOrEqualValue(ALeft, ARight.Value));
  Result.Expression := Format(TEntityCoreConstant.cExpressionLessThanOrEqual,
                              [ARight.Name, TValue.From<T>(ALeft).AsVariant]);
end;

class operator Nullable<T>.LessThanOrEqual(const ALeft: Nullable<T>; ARight: T): Nullable<Boolean>;
begin
  Result.SetValue(LessThanOrEqualValue(ALeft.Value, ARight));
  Result.Expression := Format(TEntityCoreConstant.cExpressionLessThanOrEqual,
                              [ALeft.Name, TValue.From<T>(ARight).AsVariant]);
end;

class operator Nullable<T>.LessThanOrEqual(const ALeft, ARight: Nullable<T>): Nullable<Boolean>;
begin
  Result.SetValue(LessThanOrEqualValue(ALeft.Value, ARight.Value));
  Result.Expression := Format(TEntityCoreConstant.cExpressionLessThanOrEqual,
                              [ALeft.Name, ARight.Name]);
end;

end.
