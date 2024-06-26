unit Custom.Entity.Core.Model;

interface

uses
  System.Classes,
  Custom.Entity.Core.Enum,
  Custom.Entity.Core.Attributes,
  System.Rtti,
  System.SysUtils,
  System.Generics.Collections,
  Custom.Entity.Core.Types;

type
  TEntityCoreModelClass = class of TEntityCoreModel;

  TEntityCoreModel = class(TPersistent)
  private
    FStatus        : TEntityCoreModelStatus;
    FProcedureIdKey: TProc<Int64>;
    FIsClonning    : Boolean;
    procedure SetPrimaryKey(const AIdKey: Int64);

  public
    [Ignore]
    property Status: TEntityCoreModelStatus read FStatus write FStatus;
    [Ignore]
    property ProcedureIdKey: TProc<Int64> read FProcedureIdKey write FProcedureIdKey;

    function Clone: TEntityCoreModel;
    class function GetValueInsertedDefault: TArray<TArray<Variant>>; virtual;

    constructor Create; virtual;
    destructor Destroy; override;
  end;

implementation

uses Custom.Entity.Core.Mapper, Custom.Entity.Core.Server.Helper;

{ TEntityCoreModel }

function TEntityCoreModel.Clone: TEntityCoreModel;
begin
  FIsClonning := True;

  Result := Self.NewInstance as TEntityCoreModel;

  var LProperties := TEntityCoreMapper.GetProperties(Self.ClassType);
  var LType       := TEntityCoreMapper.GetType(Result.ClassType);

  for var LProperty in LProperties do
  begin
    LType
      .GetProperty(LProperty.Name)
      .SetValue(Result, LProperty.GetValue(Self));
  end;

  Result.Status         := Self.Status;
  Result.ProcedureIdKey := Self.ProcedureIdKey;
  FIsClonning           := False;
end;


constructor TEntityCoreModel.Create;
begin
  inherited;
  if not FIsClonning then
  begin
    FProcedureIdKey :=
      procedure(AIdKey: Int64)
      begin
        SetPrimaryKey(AIdKey);
      end;
  end;
end;

destructor TEntityCoreModel.Destroy;
begin
  FProcedureIdKey := nil;
  inherited;
end;

class function TEntityCoreModel.GetValueInsertedDefault: TArray<TArray<Variant>>;
begin
end;

procedure TEntityCoreModel.SetPrimaryKey(const AIdKey: Int64);
begin
  var LPrimaryKey := TEntityCoreMapper.GetPrimaryKey(Self.ClassType);

  if (LPrimaryKey <> nil) then
  begin
    var LId: Nullable<Integer> := AIdKey;

    LPrimaryKey.SetValue(Self,
                         TValue.From(LId));
  end;
end;

end.
