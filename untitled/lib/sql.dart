import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
class Sql{
  static Database? _db;
  Future<Database?> get db async{
    if (_db==null){
      _db=await intialDB();
      return _db;
    }
    else{
      return _db;
    }
  }
  intialDB() async{
    String databasepath=await getDatabasesPath();
    String path=join(databasepath,'ALNASIKH.db');
    Database mydb=await openDatabase(path,onCreate: _onCreate,version: 1);
    return mydb;
  }
  _onCreate(Database db,int version) async{
    await db.execute('''
    CREATE TABLE alnasikh(
    id INTEGER PRIMARY KEY AUTOINCREMENT ,
    filename TEXT NOT NULL UNIQUE,
    PdfPath TEXT NOT NULL,
    ImagePath TEXT NOT NULL,
    Sentence TEXT NOT NULL,
    DATE TEXT NOT NULL,
    Merge INTEGER NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE unmerged(
    id INTEGER PRIMARY KEY AUTOINCREMENT ,
    filename TEXT NOT NULL ,
    PdfPath TEXT NOT NULL,
    ImagePath TEXT NOT NULL,
    Sentence TEXT NOT NULL,
    DATE TEXT NOT NULL,
    MergeID INTEGER NOT NULL,
    FOREIGN KEY(MergeID) REFERENCES alnasikh(id)
    )
    ''');
    print("Create");
  }

  read (String sql) async{
    Database? mydb=await db;
    List<Map> response =[];
    try{
     response=await mydb!.query(sql);
    }
    catch(e){
      print("can't");
    }
    return response;
  }
  insert (String table ,Map<String,Object> values) async{
    Database? mydb=await db;
    try{
      int response =await mydb!.insert(table,values);

      return response;
    }
    catch(e){
      print("the name is exist");
    }

  }
  update (String table ,Map<String,Object> values,String? mywhere) async{
    Database? mydb=await db;
    try{
      int response =await mydb!.update(table,values,where: mywhere);
      return response;
    }
catch(e){
      return 0;
}
  }
  delete (String table ,String? mywhere) async{
    Database? mydb=await db;
    int response =await mydb!.delete(table,where: mywhere);
    return response;
  }
}