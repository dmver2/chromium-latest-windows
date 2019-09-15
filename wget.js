var rc;
try {
	var url = WScript.Arguments(0);
	var xhr = new ActiveXObject("MSXML2.ServerXMLHTTP");

	xhr.open("GET", url, false);
	xhr.send();

	if (xhr.status === 200) {
	  if(WScript.Arguments.Length < 2) {
		WScript.Echo(xhr.responseText);
	  } else {
		var saveTo = WScript.Arguments(1);  
		var stream = new ActiveXObject("ADODB.Stream");
		stream.Open();
		stream.Type = 1; //adTypeBinary

		stream.Write(xhr.responseBody);
		stream.Position = 0; //Set the stream position to the start

		var explorer = new ActiveXObject("Scripting.FileSystemObject");
		if (explorer.Fileexists(saveTo)) { explorer.DeleteFile(saveTo); }

		stream.SaveToFile(saveTo);
		stream.Close();
	  }
	  rc = 0;
	} else {
	  rc = 1;		
	}
} catch (e) {
  rc = 2;
}
WScript.Quit(rc);