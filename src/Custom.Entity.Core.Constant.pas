unit Custom.Entity.Core.Constant;

interface

uses System.IOUtils;

type
  TEntityCoreConstant = packed record
  public const
    cSelectAll               = 'select %s from %s';
    cSelectMax               = 'select coalesce(max(%s), 0) + 1 from %s';
    cInsertSQL               = 'insert into %s(%s) values(%s) OUTPUT Inserted.%s values(%s)';
    cInsert                  = 'insert into %s(%s) values(%s) returning %s {into :%s}';
    cUpdate                  = 'update %s set %s where %s';
    cDelete                  = 'delete from %s where %s';
    cConstraintPrymaryKey    = ' constraint pk_%s primary key(%s) ';
    cCreateTable             = 'create table %s(%s)';
    cCreateUniqueKey         = 'alter table %s add constraint uq_%s unique(%s)';
    cCreatePrimaryKey        = 'alter table %s add constraint pk_%s primary key(%s)';
    cCreateForeignKey        = 'alter table %s add constraint fk_%s_%s foreign key(%s) references %s(%s)';
    cCreateDatabase          = 'create database %s';
    cDatabaseExistsSQLServer = 'select 1 from sys.databases where name = :name';
    cTableExistsSQLServer    = 'select 1 from INFORMATION_SCHEMA.TABLES a where a.TABLE_SCHEMA = ''dbo'' and a.TABLE_NAME = :tablename';
    cTableExistsFirebird     = 'select 1 from RDB$RELATIONS WHERE RDB$RELATION_NAME = :tablename';
    cFieldExistsFirebird     = 'select 1 from RDB$RELATION_FIELDS where rdb$relation_name = :tablename and rdb$field_name = :fieldname';
    cFieldExistsSQLServer    = 'select 1 from INFORMATION_SCHEMA.COLUMNS a where a.TABLE_SCHEMA = ''dbo'' and a.TABLE_NAME = :tablename and a.COLUMN_NAME = :fieldname';
    cNotNull                 = 'not null';
    cIdentity                = ' identity(1,1) ';
    cSelectVersion           = 'select case when cast(left(cast(serverproperty(''productversion'') as varchar), 4) as float) > 13 then 1 else 0 end';
    cExpressionEqual         = '%s = %s';
    cExpressionAnd           = '%s and %s';
    cExpressionOr            = '%s or %s';
    cExpressionGreatThan     = '%s > %s';
    cExpressionGreatThanOrEqual = '%s >= %s';
    cExpressionLessThan        = '%s < %s';
    cExpressionLessThanOrEqual = '%s <= %s';
    cExpressionAddNumber       = '%s + %s';
    cExpressionAddString       = '%s || %s';
    cExpressionAs              = '%s as %s';
    cCreateField               = 'alter table %s add %s %s %s';
    cEntityCfg                 = 'configuration\entity.cfg';
  end;

implementation

end.
