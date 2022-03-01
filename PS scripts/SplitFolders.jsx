 ///////////////////////////////////////////////////////////////////////////////
    // Create SmartObjects from active layers/layersets
	// Adjusts Brightness Contrast
	//Splits layers into respective folders (must have 'confocal' 'split' or 'darkfield' in name
    ///////////////////////////////////////////////////////////////////////////////

    //$.writeln( "--START SCRIPT--" );

    var curDoc = activeDocument;
	var currLayer, firstLinkLayer,cLName;
    var selLayers = GetSelectedLayersIndex();
	var numLayers= selLayers.length;
	var darkfieldLayer = activeDocument.layerSets.add();
	darkfieldLayer.name="Darkfield";
	var splitLayer = activeDocument.layerSets.add();
	splitLayer.name="Split";
	var confocalLayer = activeDocument.layerSets.add();
	confocalLayer.name="Confocal";
    // Loops through each selected layers.
    for( var i in selLayers )
    {	
        SelectLayerByIndex( selLayers[numLayers-i-1] );
		//currLayer =createSmartObject();
		//currLayer.adjustBrightnessContrast(0,0);
		//currLayer.autoContrast();
		currLayer=curDoc.activeLayer;
		cLName = currLayer.name;
		if (cLName.indexOf("confocal")!=-1) {
			currLayer.move(confocalLayer,ElementPlacement.PLACEATEND);
		}else if (cLName.indexOf("split")!=-1) {
			currLayer.move(splitLayer,ElementPlacement.PLACEATEND);
		}else if (cLName.indexOf("darkfield")!=-1) {
			currLayer.move(darkfieldLayer,ElementPlacement.PLACEATEND);
		}
			
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Basic Functions
    ///////////////////////////////////////////////////////////////////////////////

    function GetSelectedLayers()
    {
        var selectedLayers = new Array;
        var ref = new ActionReference();
        ref.putEnumerated( charIDToTypeID( "Dcmn" ), charIDToTypeID( "Ordn" ), charIDToTypeID( "Trgt" ) );
        var desc = executeActionGet( ref );
        if( desc.hasKey( stringIDToTypeID( 'targetLayers' ) ) )
       {
            desc = desc.getList( stringIDToTypeID( 'targetLayers' ) );
            var c = desc.count
            var selectedLayers = new Array();
            for( var i = 0; i < c; i++ )
            {
                selectedLayers.push(  desc.getReference( i ).getIndex() );
            }
        }
       else
       {
            var ref = new ActionReference();
            ref.putProperty( charIDToTypeID("Prpr") , charIDToTypeID( "ItmI" ));
            ref.putEnumerated( charIDToTypeID("Lyr "), charIDToTypeID("Ordn"), charIDToTypeID("Trgt") );
            selectedLayers.push( executeActionGet(ref).getInteger(charIDToTypeID( "ItmI" )));
        }
        return selectedLayers;
    }

    function SelectLayerByIndex( index, add )
    {
        //$.writeln( "Selecting layer " + index + "." );
        add == undefined ? add = false : add = true;
        var ref = new ActionReference();
        ref.putIndex(charIDToTypeID("Lyr "), index );
        var desc = new ActionDescriptor();
        desc.putReference(charIDToTypeID( "null" ), ref );
        if ( add ) desc.putEnumerated( stringIDToTypeID( "selectionModifier" ), stringIDToTypeID( "selectionModifierType" ), stringIDToTypeID( "addToSelection" ) );
        desc.putBoolean( charIDToTypeID( "MkVs" ), false );
        try
        {
            executeAction( charIDToTypeID( "slct" ), desc, DialogModes.NO );
        }
        catch(e)
        {
            alert( e.message );   
        }
    }

    function GetSelectedLayersIndex()
    {
        var selectedLayers = new Array;
        var ref = new ActionReference();
        ref.putEnumerated( charIDToTypeID("Dcmn"), charIDToTypeID("Ordn"), charIDToTypeID("Trgt") );
        var desc = executeActionGet( ref );
        try
        {
           activeDocument.backgroundLayer;
           var mod = 1;
        }
        catch(e)
        {
            var mod = 0;
        }
        if ( desc.hasKey( stringIDToTypeID( 'targetLayers' ) ) )
        {
            desc = desc.getList( stringIDToTypeID( 'targetLayers' ));
            var c = desc.count
            var selectedLayers = new Array();
            //$.writeln( "Several layers selected." );
            for( var i = 0; i < c; i++ )
            {         
                selectedLayers.push( desc.getReference( i ).getIndex() + 1 - mod );
                //$.writeln( "Storing layer " + selectedLayers[i] + "." );
            }
        }
        else
        {
            var ref = new ActionReference();
            ref.putProperty( charIDToTypeID( "Prpr" ) , charIDToTypeID( "ItmI" ) );
            ref.putEnumerated( charIDToTypeID( "Lyr " ), charIDToTypeID( "Ordn" ), charIDToTypeID( "Trgt" ) );
            selectedLayers.push( executeActionGet(ref).getInteger(charIDToTypeID( "ItmI" ) ) - mod );
            //$.writeln( "One layer selected." );
            //$.writeln("Storing layer " + selectedLayers + "." );
        }
       return selectedLayers;
    }

// create smartobject from specified layer (default is active layer)
function createSmartObject(layer)
{
   var doc = app.activeDocument;
   var layer = layer != undefined ? layer : doc.activeLayer;
   
   if(doc.activeLayer != layer) doc.activeLayer = layer;
   
   try
   {
      var idnewPlacedLayer = stringIDToTypeID( "newPlacedLayer" );
      executeAction( idnewPlacedLayer, undefined, DialogModes.NO );
      return doc.activeLayer;
   }
   catch(e)
   {
      return undefined;
   }
}