"use strict";
/*--------------------------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
 *-------------------------------------------------------------------------------------------------------------*/
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const core = __importStar(require("@actions/core"));
const generateDocs_1 = require("./generateDocs");
const utils_1 = require("./utils");
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        core.debug('Reading input parameters...');
        // Read inputs
        const shouldPublishFeatures = core.getInput('publish-features').toLowerCase() === 'true';
        const shouldPublishTemplate = core.getInput('publish-templates').toLowerCase() === 'true';
        const shouldGenerateDocumentation = core.getInput('generate-docs').toLowerCase() === 'true';
        let featuresMetadata = undefined;
        let templatesMetadata = undefined;
        if (shouldPublishFeatures) {
            core.info('Publishing features...');
            const featuresBasePath = core.getInput('base-path-to-features');
            featuresMetadata = yield packageFeatures(featuresBasePath);
        }
        if (shouldPublishTemplate) {
            core.info('Publishing template...');
            const basePathToDefinitions = core.getInput('base-path-to-templates');
            templatesMetadata = undefined; // TODO
            yield packageTemplates(basePathToDefinitions);
        }
        if (shouldGenerateDocumentation) {
            core.info('Generating documentation...');
            const featuresBasePath = core.getInput('base-path-to-features');
            if (featuresBasePath) {
                yield (0, generateDocs_1.generateFeaturesDocumentation)(featuresBasePath);
            }
            else {
                core.error("'base-path-to-features' input is required to generate documentation");
            }
            // TODO: base-path-to-templates
        }
        // TODO: Programatically add feature/template fino with relevant metadata for UX clients.
        core.info('Generation metadata file: devcontainer-collection.json');
        yield (0, utils_1.addCollectionsMetadataFile)(featuresMetadata, templatesMetadata);
    });
}
function packageFeatures(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            core.info(`Archiving all features in ${basePath}`);
            const metadata = yield (0, utils_1.getFeaturesAndPackage)(basePath);
            core.info('Packaging features has finished.');
            return metadata;
        }
        catch (error) {
            if (error instanceof Error) {
                core.setFailed(error.message);
            }
        }
        return;
    });
}
function packageTemplates(basePath) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            core.info(`Archiving all templated in ${basePath}`);
            yield (0, utils_1.getTemplatesAndPackage)(basePath);
            core.info('Packaging templates has finished.');
        }
        catch (error) {
            if (error instanceof Error)
                core.setFailed(error.message);
        }
    });
}
run();
