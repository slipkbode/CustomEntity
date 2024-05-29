unit Custom.Entity.Core.Constant;

interface

uses System.IOUtils;

type
  TEntityCoreConstant = packed record
  public const
    cSelectAll                  = 'select %s from %s';
    cSelectMax                  = 'select coalesce(max(%s), 0) + 1 from %s';
    cInsertSQLNoReturn          = 'insert into %s(%s) values(%s)';
    cInsertSQL                  = 'insert into %s(%s) values(%s) OUTPUT Inserted.%s values(%s)';
    cInsert                     = 'insert into %s(%s) values(%s) returning %s {into :%s}';
    cUpdate                     = 'update %s set %s where %s';
    cDelete                     = 'delete from %s where %s';
    cConstraintPrymaryKey       = ' constraint pk_%s primary key(%s) ';
    cCreateTable                = 'create table %s(%s)';
    cCreateUniqueKey            = 'alter table %s add constraint uq_%s unique(%s)';
    cCreatePrimaryKey           = 'alter table %s add constraint pk_%s primary key(%s)';
    cCreateForeignKey           = 'alter table %s add constraint fk_%s_%s foreign key(%s) references %s(%s)';
    cCreateDatabase             = 'create database %s';
    cDropUniqueKey              = 'alter table %s drop constraint %s';
    cDropUniqueKeyMySQL         = 'alter table %s drop index %s';
    cDatabaseExistsSQLServer    = 'select 1 from sys.databases where name = :name';
    cTableExistsSQLServer       = 'select 1 from INFORMATION_SCHEMA.TABLES a where a.TABLE_SCHEMA = ''dbo'' and a.TABLE_NAME = :tablename';
    cTableExistsFirebird        = 'select 1 from RDB$RELATIONS WHERE RDB$RELATION_NAME = :tablename';
    cFieldExistsFirebird        = 'select 1 from RDB$RELATION_FIELDS where rdb$relation_name = :tablename and rdb$field_name = :fieldname';
    cFieldExistsSQLServer       = 'select 1 from INFORMATION_SCHEMA.COLUMNS a where a.TABLE_SCHEMA = ''dbo'' and a.TABLE_NAME = :tablename and a.COLUMN_NAME = :fieldname';
    cUniqueKeyExistsSQLServer   = 'SELECT STRING_AGG(CCU.COLUMN_NAME, '','') AS COLUMNS FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS CCU '
                                  + 'ON TC.CONSTRAINT_CATALOG = CCU.CONSTRAINT_CATALOG AND TC.CONSTRAINT_SCHEMA = CCU.CONSTRAINT_SCHEMA AND TC.CONSTRAINT_NAME = CCU.CONSTRAINT_NAME '
                                  + 'WHERE TC.CONSTRAINT_TYPE = ''UNIQUE'' AND TC.TABLE_NAME = :TABLENAME AND TC.CONSTRAINT_NAME = :uniquekey';
    cUniqueKeyExistsFirebird    = 'select LIST(TRIM(sg.rdb$field_name), '','') as field_name from rdb$indices ix '+
                                  'inner join rdb$index_segments sg on ix.rdb$index_name = sg.rdb$index_name ' +
                                  'inner join rdb$relation_constraints rc on rc.rdb$index_name = ix.rdb$index_name ' +
                                  'where rc.rdb$constraint_type = ''UNIQUE'' AND rc.rdb$relation_name = :tablename and ix.rdb$index_name = :uniquekey';
    cNotNull                    = 'not null';
    cIdentity                   = ' identity(1,1) ';
    cSelectVersion              = 'select case when cast(left(cast(serverproperty(''productversion'') as varchar), 4) as float) > 13 then 1 else 0 end';
    cExpressionEqual            = '%s = %s';
    cExpressionAnd              = '%s and %s';
    cExpressionOr               = '%s or %s';
    cExpressionGreatThan        = '%s > %s';
    cExpressionGreatThanOrEqual = '%s >= %s';
    cExpressionLessThan         = '%s < %s';
    cExpressionLessThanOrEqual  = '%s <= %s';
    cExpressionAddNumber        = '%s + %s';
    cExpressionAddString        = '%s || %s';
    cExpressionAs               = '%s as %s';
    cCreateField                = 'alter table %s add %s %s %s';
    cEntityCfg                  = 'configuration\entity.cfg';
    cHtml                       = '''
                                 <!DOCTYPE html>
                                   <html>
                                     <head>
                                       <title>Servidor de Aplicação </title>
                                     </head>
                                     <body>
                                       <h1>Servidor está on - line</h1>
                                       <p>Verificação do Servidor da API se está on - line</p>
                                       <p>@@error</p>
                                     </body>
                                   </html>
                                 ''';
  end;

implementation

end.
