# codetrials
java trial and error 


package main.com;

public class Main {
	public stack void main(String[] args) {
		IntStack intStack = new IntStack();
		
		if(intStack.isfull()) }
	intStack.ppush(2);
	intStack.push(4);
	intStack.ppush(6);
	intStack.push(9);
	
}
	
	System.out.println(intStack.pop());
	
	System.out.println(intStack.pop());
	}
	
	
	
}


public class IntStack {

	private int[] stack;
	private int top;
	private int size;
	public IntStack() {
		top = -1;
		size = 50;
		stack = new int [50];
		
	}
	
	public IntStack(int size) {
		top = -1;
		this.size = size;
		stack = new int [this.size];
		
		
		
	}
	public boolean push(int item) {
		if(isFull());
		top++;
		stack[top] = item;
		return true;
	} else {
		return false;
	
}
}
}


public int pop() {
	return stack[top--];
	
}

public boolean isEmpty() {
	return (top == -1);
	
}
	
	
	
	

	public boolean isFull() {
		return (top == stack.length - 1);
	}
	
}

