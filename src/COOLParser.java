import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CharStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.tree.CommonTree;
import org.antlr.runtime.tree.CommonTreeNodeStream;

class ANTLRNoCaseInputStream  extends ANTLRInputStream {
    public ANTLRNoCaseInputStream(InputStream fileName) throws IOException {
        super(fileName, null);
    }

    public ANTLRNoCaseInputStream(InputStream fileName, String encoding)
    throws IOException {
        super(fileName, encoding);
    }

    public int LA(int i) {
        if ( i==0 ) {
            return 0; // undefined
        }
        if ( i<0 ) {
            i++; // e.g., translate LA(-1) to use offset 0
        }

        if ( (p+i-1) >= n ) {

            return CharStream.EOF;
        }
        return Character.toUpperCase(data[p+i-1]);
    }
}
public class COOLParser {

	/**
 	* TODO: Feel free to change or rewrite the entire structure below,
 	* according to your needs. It is just a sample starting point,
 	* that successfully uses the available API.
 	*/ 	




	public static CommonTokenStream prepareParsing(InputStream is)
			throws IOException {
		ANTLRNoCaseInputStream input = new ANTLRNoCaseInputStream(is);
		COOLTreeBuilderLexer lexer = new COOLTreeBuilderLexer(input);
		
		CommonTokenStream tokenStream = new CommonTokenStream(lexer);
		
		return tokenStream;
	}
	
	public static CommonTree buildCOOLTree(InputStream is)
			throws IOException, RecognitionException {
		CommonTokenStream tokenStream = prepareParsing(is);
		
		COOLTreeBuilderParser parser = new COOLTreeBuilderParser(tokenStream);
		
		COOLTreeBuilderParser.program_return retVal = 
			parser.program();
		
		return (CommonTree)retVal.getTree();
	}
	
	public static void generateOutputData(Classes cl, CommonTree ast,
			String fileName) 
			throws RecognitionException {
		CommonTreeNodeStream nodeStream = new CommonTreeNodeStream(ast);
		
		COOLTreeChecker checker = new COOLTreeChecker(nodeStream);
		checker.setFileName(fileName);
		
		checker.program(cl);
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		/* There should be one class list per program. This list would
                   collect the classes from all the source files that mycoolc
		   takes at the command line.
		*/ 		
		Classes cl = new Classes(1);
		Program prg = new program(1, cl);
		
		// Command line processing (you may modify it at will)
		args = Flags.handleFlags(args);
		
		/*
		 * TODO: You can change the code below and implement a different
		 * strategy, such as concatenating input source files and then
		 * analyzing them as a whole using ANTLR.
		 * 
		 * The current strategy creates an ANTLR AST for each compilation file,
		 * and during tree parsing, each detected class is added to the
		 * global class list. Note that this strategy needs additional semantic
		 * checking after all the classes have been added to the list.
		 */
		
		try {
			
			for (String fname: args) { // Iterate through the input file names
				CommonTree rootNode = null;
				FileInputStream fis = new FileInputStream(fname);
				
				rootNode = buildCOOLTree(fis); // Build the ANTLR AST
			
				// Parse the AST and add the partial results to the class list	
				generateOutputData(cl, rootNode, fname);
				
				fis.close();
			}
			
			/*
			 * TODO: You MAY need to perform additional semantic checking
			 * here, if you have multiple files. For this to happen, implement
			 * 
			 * prg.semant()
			 * 
			 * and additional semant() methods in each of the classes
			 * in cool-tree.java.
			 */
			
			//prg.semant()

			// Important: Do not remove this line!
			prg.dump_with_types(System.out, 0);
			
		} catch (IOException ex) {
			// TODO: Implement your own exception handling here
			ex.printStackTrace();
		} catch (RecognitionException ex) {
			ex.printStackTrace();
		}
		

	}

}
