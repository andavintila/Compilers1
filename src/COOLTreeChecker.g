tree grammar COOLTreeChecker;

options {
	tokenVocab = COOLTreeBuilder;
	ASTLabelType = CommonTree;
}

@members {
	private String fileName = "Unnamed"; // The file name is needed by the tree API.
	
	public String getFileName() { return fileName; }
	public void setFileName(String fileName) { this.fileName = fileName; }
	/*am adaugat aici metoda pentru transformarea corecta a sirului de caractere;
	caut pentru fiecare caracter daca este escaped si elimin '\'-urile suplimentare*/
	public static String transform(String str) {
    		StringBuilder s = new StringBuilder();
    		for (int i = 1; i < str.length() - 1; i++) 
      			if (str.charAt(i) == '\\')
      				switch(str.charAt(++i)){
      					case 'n': s.append('\n'); break;
    					case 'b': s.append('\b'); break;
    					case 't': s.append('\t'); break;
    					case 'f': s.append('\f'); break;
    					default: s.append(str.charAt(i));
      				}
         			else s.append(str.charAt(i));
         		return s.toString();
  	}
	
}

// TODO: You have below a sample ANTLR AST parser that makes use of the tree API to
// generate a valid tree to be serialized to the output.
// You must extend / rewrite it to your own needs.

program [Classes cl]
	: (classdef { $cl.appendElement($classdef.result); })+
	;
	
classdef returns [class_ result]
	: ^(CLASS name=ID features)
	{
		$result = new class_($CLASS.line,
			AbstractTable.idtable.addString($name.text),
			AbstractTable.idtable.addString("Object"),
			$features.result,
			AbstractTable.stringtable.addString(getFileName()));
			
	}
	| ^(CLASS name=ID parent=ID features)
	{
		$result = new class_($CLASS.line,
			AbstractTable.idtable.addString($name.text),
			AbstractTable.idtable.addString($parent.text),
			$features.result,
			AbstractTable.stringtable.addString(getFileName()));
	}
	;
	
features returns [Features result]
	: ^(FEATURES { $result = new Features($FEATURES.line); } 
		(feature { $result.appendElement($feature.result); })*
	   )
	;
	
feature returns [Feature result]
	: ^(METHOD name=ID formals type=ID   a=assign)
	{
    		$result = new method($METHOD.line,
    			AbstractTable.idtable.addString($name.text),
    			$formals.result, AbstractTable.idtable.addString($type.text),
    			 $a.result);
    	}
    	| ^(ATTRIBUTE name=ID type=ID)
    	{
    		$result = new attr($ATTRIBUTE.line,
    			AbstractTable.idtable.addString($name.text),
    			AbstractTable.idtable.addString($type.text),
    			new no_expr(0));
    	}
    	| ^(ATTRIBUTE name=ID type=ID a=assign)
    	{
    		$result = new attr($ATTRIBUTE.line,
    			AbstractTable.idtable.addString($name.text),
    			AbstractTable.idtable.addString($type.text),
    			$a.result);    
    	}
    	;
    	
formals returns [Formals result] 
	: ^(FORMALS { $result = new Formals($FORMALS.line); }
		(formal { $result.appendElement($formal.result); })*
	  )
	;

formal returns [formal result]
	:^(FORMAL name=ID type=ID)
	{
    		$result = new formal($name.line,
    			AbstractTable.idtable.addString($name.text),
    		 	AbstractTable.idtable.addString($type.text));
    	}
    	;

/*assign este regula in care se potrivesc toate tipurile de noduri si ea returneaza un obiect de tip Expression
pentru ca toate clasele ce definesc nodurile il au ca parinte */
assign returns [Expression result]
	: ^( BLOCK
	{
		Expressions exp = new Expressions($BLOCK.line);
		$result = new block($BLOCK.line, exp);
	} 
	(b=assign {exp.appendElement($b.result);} )*
	)
	| ^(ASSIGN name=ID a=assign)
	{	
		$result = new assign($ASSIGN.line,
			AbstractTable.idtable.addString($name.text), $a.result);
	}
	| ^(NOT a1=assign)
	{	
		$result = new comp($NOT.line, $a1.result);
	}
	| ^(LEQ e1=assign e2=assign)
	{	
		$result = new leq($LEQ.line, $e1.result, $e2.result);
	}
	| ^(LESS lt1=assign lt2=assign)
	{	
		$result = new lt($LESS.line, $lt1.result, $lt2.result);
	}
	| ^(EQ eq1=assign eq2=assign)
	{	
		$result = new eq($EQ.line, $eq1.result, $eq2.result);
	}
	| ^(PLUS p1=assign p2=assign)
	{	
		$result = new plus($PLUS.line, $p1.result, $p2.result);
	}
	| ^(MINUS m1=assign m2=assign)
	{	
		$result = new sub($MINUS.line, $m1.result, $m2.result);
	}
	| ^(MUL mul1=assign mul2=assign)
	{	
		$result = new mul($MUL.line, $mul1.result, $mul2.result);
	}
	| ^(DIVIDE d1=assign d2=assign)
	{	
		$result = new divide($DIVIDE.line, $d1.result, $d2.result);
	}
	| ^(ISVOID iv=assign)
	{	
		$result = new isvoid($ISVOID.line, $iv.result);
	}
	| ^(COMPL c=assign)
	{	
		$result = new neg($COMPL.line, $c.result);
	}
	| fid = ID
	{
		$result = new object($fid.line, AbstractTable.idtable.addString($fid.text));
	}
	| ^(NEW type=ID)
	{
		$result = new new_($type.line, AbstractTable.idtable.addString($type.text)); 
	}
	| t = TRUE
	{
		$result = new bool_const($t.line, true);
	}
	| f = FALSE
	{
		$result = new bool_const($f.line, false);
	}
	| int_=INTEGER 
	{
		$result = new int_const($INTEGER.line,
			AbstractTable.inttable.addInt(Integer.parseInt($int_.text)));
	}
	| ^(STR str_=STRING)
	{	
		String tmpString = transform($str_.text);
		$result = new string_const($STR.line,
			new StringSymbol(tmpString, tmpString.length(), 0));
		
	}
	//cele 3 tipuri de dispatch: static, normal si self
	| ^(AT dsp1=assign ^(DOT type=ID ^(ft1=ID ^(LEFT_BR
	{	
		Expressions st_dsp_exp = new Expressions($AT.line);
		$result = new static_dispatch($AT.line, $dsp1.result,
			AbstractTable.idtable.addString($type.text),
			AbstractTable.idtable.addString($ft1.text),
			st_dsp_exp);
	}
	(dsp2=assign {st_dsp_exp.appendElement($dsp2.result);} )* 
	))))
	| ^(DISPATCH dsp3=assign ^(ft2=ID ^(LEFT_BR
	{
		Expressions dsp_exp = new Expressions($DISPATCH.line);
		$result = new dispatch($DISPATCH.line, $dsp3.result,
			AbstractTable.idtable.addString($ft2.text),
			dsp_exp);
	}
	(dsp4=assign {dsp_exp.appendElement($dsp4.result);} )* 
	)))
	| ^(SELF_DISPATCH ^(ft3=ID ^(LEFT_BR
	{
		Expressions sdsp_exp = new Expressions($ID.line);
		Expression st = new object($ID.line, AbstractTable.idtable.addString("self"));
          		st.set_type(AbstractTable.idtable.addString("SELF_TYPE"));
		$result = new dispatch($ft3.line, st,
			AbstractTable.idtable.addString($ft3.text),
			sdsp_exp);
	}
	(dsp5=assign {sdsp_exp.appendElement($dsp5.result);} )* 
	)))
	//constructie pentru instructiunea conditie (valabil si pentru inlineif)
	| ^(IF pred=assign THEN then_exp=assign ELSE else_exp=assign)
	{
		$result = new cond($IF.line, $pred.result,
			$then_exp.result, $else_exp.result);
	}
	| ^(WHILE wpred=assign LOOP body=assign)
	{
		$result = new loop($WHILE.line, $wpred.result, $body.result);
	}
	| ^(CASE c1=assign OF
	{	
		Cases cs= new Cases($CASE.line);
		$result = new typcase($CASE.line, $c1.result, cs);
	} 
	(f_br=ID t_br=ID c2=assign 
	{
		cs.appendElement(new branch($f_br.line,
			AbstractTable.idtable.addString($f_br.text),
			AbstractTable.idtable.addString($t_br.text),
			$c2.result
			));
	}
	)*)
	//2 alternative pentru let: cu variabila initializata si fara
	| ^(LET identif2=ID tp2=ID init2=assign IN body2=assign)
	{
		$result = new let($identif2.line, 
			AbstractTable.idtable.addString($identif2.text),
			AbstractTable.idtable.addString($tp2.text),
			$init2.result,
			$body2.result
			);
	}
	| ^(LET identif1=ID tp1=ID IN body1=assign)
	{
		$result = new let($identif1.line, 
			AbstractTable.idtable.addString($identif1.text),
			AbstractTable.idtable.addString($tp1.text),
			new no_expr(0),
			$body1.result
			);
	}
	;