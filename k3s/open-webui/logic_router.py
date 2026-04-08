"""
title: Logic & Math Router (Nemotron)
author: bavsworld
author_url: https://gemini.example.com
version: 1.0
"""

import os
import requests
from typing import List, Union, Generator, Iterator

class Filter:
    def __init__(self):
        # The model to route math/logic questions to
        self.logic_model = "nemotron-mini-xip"
        # Keywords that trigger routing to the math/logic specialist.
        # Kept specific to avoid false positives on casual mentions.
        self.trigger_keywords = [
            # Arithmetic & algebra
            "calculate", "compute", "evaluate", "simplify",
            "solve for", "equation", "inequality", "polynomial",
            "factor", "factorize", "expand",
            # Calculus
            "integral", "integrate", "derivative", "differentiate",
            "limit", "differential equation",
            # Statistics & probability
            "probability", "statistics", "standard deviation",
            "variance", "mean", "median", "regression",
            # Discrete math & proofs
            "proof", "prove that", "theorem", "induction",
            "combinatorics", "permutation", "combination",
            "boolean algebra", "truth table", "logical operator",
            # Physics & engineering math
            "eigenvalue", "eigenvector", "matrix", "vector calculus",
            "fourier", "laplace transform",
        ]

    def inlet(self, body: dict, __user__: dict) -> dict:
        print(f"Checking message for logic/math intent: {body['messages'][-1]['content']}")
        
        last_message = body['messages'][-1]['content'].lower()
        
        # Check if any trigger keyword is in the message
        is_logic_task = any(keyword in last_message for keyword in self.trigger_keywords)
        
        if is_logic_task:
            print(f"Logic intent detected. Routing to {self.logic_model}")
            # Switch the model for this request
            body['model'] = self.logic_model
            
        return body

    def outlet(self, body: dict, __user__: dict) -> dict:
        return body
